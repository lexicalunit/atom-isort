import io
import json
import os
import sys
from contextlib import contextmanager

import isort

sys.dont_write_bytecode = True


@contextmanager
def silence_stdout():
    new_target = open(os.devnull, 'w')
    old_target, sys.stdout = sys.stdout, new_target
    try:
        yield new_target
    finally:
        sys.stdout = old_target


class IsortTools(object):
    def __init__(self):
        self.default_sys_path = sys.path
        self._input = io.open(sys.stdin.fileno(), encoding='utf-8')

    def _serialize_response(self, response_type, response_dict):
        '''Returns a json dump combining `response_dict` and `response_type`.

        `response_type` is keyed to 'type', and that dict is merged with
        `response_dict` (without overwriting `response_dict`).

        Args:
            response_type (str): The type of json response, eg:
                'sort_text', 'check_text'
            response_dict (dict): The dictionary of response values, eg:
                'new_contents':(str), 'correctly_sorted':(bool)

        Returns:
            A json dump of `response_dict`, with the added key-value pair of
            'type':`response_type`.
        '''
        retdict = {'type': response_type}
        retdict.update(response_dict)
        return json.dumps(retdict)

    def _process_request(self, request):
        '''Processes json request, writes appropriate response.

        eg: If the `request['type']` is 'sort_text', write a json dict
        containing a sorted version of `request['file_contents']` via
        `self._write_response`.


        Args:
            request (str): A string representing a json dump made by this
                script must have 'file_contents', 'file_path', and 'type' keys.
        '''
        request = json.loads(request)

        with silence_stdout():
            new_contents = isort.SortImports(file_contents=request['file_contents'],
                                             file_path=request.get('file_path'),
                                             write_to_stdout=True).output

        if request['type'] == 'sort_text':
            self._write_response(
                self._serialize_response('sort_text_response',
                                         {'new_contents': new_contents}))

        elif request['type'] == 'check_text':

            # NOTE: Some explanation required:
            # Since we are using stdout, we can't use the default 'check=True'
            # option, since isort will write to sdtout if there are errors,
            # and this cannot be overridden with a function call. However, we
            # can replicate the behavior by sorting imports and then comparing
            # to the unsorted text. If they are different, then they are not
            # sorted.

            if len(request['file_contents'].split()) == 0:
                correctly_sorted = True
            else:
                correctly_sorted = (new_contents == request['file_contents'])

            self._write_response(
                self._serialize_response('check_text_response', {
                    'correctly_sorted': correctly_sorted,
                }))

    def _write_response(self, response):
        '''Writes a string to stdout, to be read by 'lib/atom-isort.coffee'.

        Args:
            response (string): A string representing a json dump readable by
                'lib/atom-isort.coffee'.
        '''
        sys.stdout.write('__' + 'ATOM_ISORT_SENTRY' + '__')
        sys.stdout.write(response + '\n')
        sys.stdout.flush()

    def read_and_process(self):
        '''Reads input, then calls self._process_request on it.
        '''
        data = self._input.readline()

        if len(data) == 0:
            raise EnvironmentError('io recieved no data.')

        self._process_request(data)
        return

if __name__ == '__main__':
    IsortTools().read_and_process()
    quit()
