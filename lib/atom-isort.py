import io
import json
import os
import sys
import traceback

from numpy import arange, array

try:
    import isort
    could_not_find_isort = False
except ImportError:
    could_not_find_isort = True


class IsortTools(object):
    def __init__(self):
        self.default_sys_path = sys.path
        self._input = io.open(sys.stdin.fileno(), encoding='utf-8')

    @classmethod
    def _get_top_level_module(cls, path):
        """Recursively walk through directories looking for top level module.
        Jedi will use current filepath to look for another modules at same path,
        but it will not be able to see modules **above**, so our goal
        is to find the higher python module available from filepath.
        """
        _path, _ = os.path.split(path)
        if os.path.isfile(os.path.join(_path, '__init__.py')):
            return cls._get_top_level_module(_path)
        return path

    def _serialize(self, response_type, response):
        return json.dumps({
            'type': response_type,
            'new_contents': response,
        })

    def _process_request(self, request):
        if could_not_find_isort:
            raise ImportError("Could not find isort package.")

        request = json.loads(request)

        # These seem unnecessary if we're not affecting the file itself:

        #   path = self._get_top_level_module(request.get('path', ''))
        #   if path not in sys.path:
        #     sys.path.insert(0, path)

        #   project_paths = (request.get('project_paths', []))
        #   for project_path in project_paths:
        #       project_path_top_module = self._get_top_level_module(project_path)
        #       if project_path_top_module not in sys.path:
        #           sys.path.insert(0, project_path_top_module)


        # TODO:
        # 1. Read more about isort options: https://github.com/timothycrosley/isort/wiki/isort-Settings
        #   a. Which settings are neceessary/useful?
        #   b. isort options include eg line_length, can we read this from
        #       editor settings?
        #   c. note: Options can be easily passed as json from JS, and as
        #       kwargs in the SortImports function.
        # 2. Add support for isort check? Is that really important?

        if request['type'] == 'sort_text':
            new_contents = isort.SortImports(
                file_contents=request['source']).output
            self._write_response(
                self._serialize('sort_text_response', new_contents))
        elif request['type'] == 'check_text':
            # TODO
            # also should figure out if json can pass bools from py to js
            pass

    def _write_response(self, response):
        sys.stdout.write(response + '\n')
        sys.stdout.flush()

    def watch(self):
        while True:
            # TODO: this try block is redundant with 93-98
            try:
                data = self._input.readline()

                # Check if the connection has been broken
                if len(data) == 0:
                    break

                self._process_request(data)
            except Exception as e:
                error_response = json.dumps({'type': 'error', 'error': str(e)})
                sys.stdout.write(error_response + '\n')
                sys.stdout.flush()


if __name__ == '__main__':
    try:
        IsortTools().watch()
    except Exception as e:
        error_response = json.dumps({'type': 'error', 'error': str(e)})
        sys.stdout.write(error_response + '\n')
        sys.stdout.flush()
