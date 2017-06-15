import io
import json
import sys

# Isort is imported in try block at bottom of file.


class IsortTools(object):
    def __init__(self):
        self.default_sys_path = sys.path
        self._input = io.open(sys.stdin.fileno(), encoding='utf-8')

    def _serialize(self, response_type, response_dict):
        retdict = {'type': response_type}
        retdict.update(response_dict)
        return json.dumps(retdict)

    # TODO for _process_request:
    # 1. Read more about isort options: https://github.com/timothycrosley/isort/wiki/isort-Settings
    #   a. Which settings are neceessary/useful?
    #   b. isort options include eg line_length, read this from
    #       editor settings

    def _process_request(self, request):

        request = json.loads(request)

        if request['type'] == 'sort_text':
            new_contents = isort.SortImports(
                file_contents=request['source']).output

            self._write_response(
                self._serialize('sort_text_response',
                                {'new_contents': new_contents}))

        elif request['type'] == 'check_text':
            # Some explanation required:
            # Since we are using stdout, we can't use the default 'check=True'
            # option, since isort will write to sdtout if there are errors,
            # and this cannot be overridden. However, we can replicate the
            # behavior by sorting imports and then comparing to the unsorted
            # text. If they are different, then they are not sorted.
            if len(request['source'].split()) == 0:
                correctly_sorted = True
            else:
                new_text = isort.SortImports(
                    file_contents=request['source']).output

                correctly_sorted = (
                    new_text.split('\n') == request['source'].split('\n'))

            self._write_response(
                self._serialize('check_text_response', {
                    'correctly_sorted': correctly_sorted,
                }))

    def _write_response(self, response):
        sys.stdout.write(response + '\n')
        sys.stdout.flush()

    def watch(self):
        while True:
            data = self._input.readline()

            # Check for broken connection. Raise error here?
            if len(data) == 0:
                break

            self._process_request(data)


if __name__ == '__main__':
    try:
        import isort
        IsortTools().watch()
    except Exception as e:
        error_response = json.dumps({'type': 'error', 'error': str(e)})
        sys.stdout.write(error_response + '\n')
        sys.stdout.flush()
