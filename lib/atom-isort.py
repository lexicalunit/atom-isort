import io
import json
import sys

# Isort is imported in try block at bottom of file.


class IsortTools(object):
    def __init__(self):
        self.default_sys_path = sys.path
        self._input = io.open(sys.stdin.fileno(), encoding='utf-8')

    def _serialize(self, response_type, response_dict):
        return json.dumps({'type': response_type}.update(response_dict))

    # TODO for _process_request:
    # 1. Read more about isort options: https://github.com/timothycrosley/isort/wiki/isort-Settings
    #   a. Which settings are neceessary/useful?
    #   b. isort options include eg line_length, read this from
    #       editor settings
    #   c. note: Options can be easily passed as json from JS, and as
    #       kwargs in the SortImports function.
    # 2. Add support for isort check? Is that really important?

    def _process_request(self, request):
        if could_not_find_isort:
            raise ImportError("Could not find isort package.")

        request = json.loads(request)

        if request['type'] == 'sort_text':
            new_contents = isort.SortImports(
                    file_contents=request['source']).output

            self._write_response(
                self._serialize('sort_text_response', new_contents))

        elif request['type'] == 'check_text':
            # TODO
            pass

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
