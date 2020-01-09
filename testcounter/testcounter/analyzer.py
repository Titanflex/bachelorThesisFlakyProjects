import csv
import os
from pathlib import Path


class Analyzer:

    def __init__(self):
        self._projects = {}
        self._nbr_flaky_tests = 0
        self._nbr_all_tests = 0
        self._nbr_all_tests_in_flaky = 0

    def run(self) -> None:
        """Runs the analysis."""
        self._get_tests()
        self._analyse_test_results()
        self._write_output_csv()

    def _get_tests(self):
        path_all_tests = Path(__file__).parent / "../alltestresults.csv"
        print(path_all_tests)
        self._flaky_testcases = os.path.exists(path_all_tests)
        self._test_cases = os.path.exists(path_all_tests)
        if self._flaky_testcases and self._test_cases:
            with open(path_all_tests) as f:
                self._projects = list(csv.reader(f))

    def _analyse_test_results(self):
        for project in self._projects:
            print(project)
            self._nbr_flaky_tests = self._nbr_flaky_tests + int(project[1])
            self._nbr_all_tests = self._nbr_all_tests + int(project[2])
            if int(project[1]) > 0:
                self._nbr_all_tests_in_flaky = self._nbr_all_tests
            print(self._nbr_flaky_tests)
            print(self._nbr_all_tests)
        print(self._nbr_all_tests_in_flaky)

    def _write_output_csv(self):
        csvdirectory = os.path.join(os.getcwd(), "countedTests.csv")
        with open(csvdirectory, "w") as fd:
            writer = csv.writer(fd, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
            writer.writerow([self._nbr_flaky_tests, self._nbr_all_tests_in_flaky, self._nbr_all_tests])