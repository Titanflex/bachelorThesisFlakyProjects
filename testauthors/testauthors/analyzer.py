import argparse
import csv
import logging
import os
import subprocess
from pathlib import Path

from typing import List


class Analyzer:


    def __init__(self, argv: List[str]) -> None:
        parser = self._create_parser()
        self._config = parser.parse_args(argv[1:])
        self._logger = self._configure_logger()
        self.analysis_dir = self._config.analysisdir
        self._repo_path = self._config.repository
        self._tl_dir = self._config.tldir
        self._url = self._config.url
        self._repo_name = self._extract_repo_name(self._repo_path)
        self._flaky_testcases = {}
        self._test_cases = {}
        self._flaky_test_authors = 0
        self._nonflaky_test_authors = 0

    @staticmethod
    def _extract_repo_name(path):
        _, repo_name = os.path.split(path)
        return repo_name

    def run(self) -> None:
        self._get_tests()
        if not self._flaky_testcases:
            self._write_output_csv(2)
        elif not self._test_cases :
            self._write_output_csv(1)
        else:
            self._analyse_test_results()
            self._write_output_csv(0)

    def _get_tests(self):
        path_all_tests = Path(__file__).parent / "../all_tests/{}.csv".format(self._repo_name)
        print(path_all_tests)
        path_flaky_tests = Path(__file__).parent / "../flaky_tests/{}.csv".format(self._repo_name)
        self._flaky_testcases = os.path.exists(path_flaky_tests)
        self._test_cases = os.path.exists(path_all_tests)
        if self._flaky_testcases and self._test_cases:
            with open(path_all_tests) as f:
                self._test_cases = list(csv.reader(f))
                print(self._test_cases)
            with open(path_flaky_tests) as f:
                flaky_tests = list(csv.reader(f))[0]
                print(flaky_tests)
                self._flaky_testcases = flaky_tests[3].split("|")


    def _analyse_test_results(self):
        for test_case in self._test_cases:
            testcase_hierarchy = test_case[0].split(".")
            filename = ""
            old_dir = os.getcwd()
            os.chdir(self._repo_path)
            directorypath = self._repo_path
            for testcase_word in testcase_hierarchy:
                test_file_path = os.path.join(directorypath, testcase_word + ".py")
                print(test_file_path)
                if os.path.exists(test_file_path):
                    filename = "{}.py".format(testcase_word)
                    print(filename)
                    break
                else:
                    directorypath = os.path.join(directorypath, testcase_word + "/")
            cmd = ["find","-type","f","-name","{}".format(filename),"-exec","git","log","-L {},{}:".format(test_case[1], test_case[2]) + "{}",";"]
            proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            o, e = proc.communicate()
            os.chdir(old_dir)
            o = o.decode("utf-8")
            print("CMD Error " + e.decode("utf-8"))
            unique_authors = set()
            for item in o.split("\n"):
                if "Author:" in item:
                    authorname = str(item.split(" ",1)[1].split("<",1)[0])
                    print("Authors {}".format(authorname.lower()))
                    unique_authors.add(authorname.lower())
            if test_case[0] in self._flaky_testcases:
                self._flaky_test_authors = self._flaky_test_authors + len(unique_authors)
                print("flaky test {} authors {}".format(test_case, self._flaky_test_authors))
            else:
                self._nonflaky_test_authors = self._nonflaky_test_authors + len(unique_authors)
                print("non flaky test {} authors {}".format(test_case, self._nonflaky_test_authors))




    def _write_output_csv(self, completed_testsuite):
        csvdirectory = self._config.output
        if completed_testsuite != 0:
            if completed_testsuite == 1:
                csvdirectory = os.path.join(csvdirectory, "incomplete/notestcasefile")
            else:
                csvdirectory = os.path.join(csvdirectory, "incomplete/noflakytestfile")
            csvdirectory = os.path.join(csvdirectory, self._repo_name + ".csv")
            with open(csvdirectory, "w") as fd:
                writer = csv.writer(fd, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
                writer.writerow([self._repo_name, self._url])
        else:
            print(self._flaky_test_authors)
            print(len(self._flaky_testcases)-1)
            flaky_testcases_length = 0
            if (len(self._flaky_testcases)-1) == 0:
                csvdirectory = os.path.join(csvdirectory, "notflaky/")
                csvdirectory = os.path.join(csvdirectory, self._repo_name + ".csv")
                with open(csvdirectory, "w") as fd:
                    writer = csv.writer(fd, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
                    writer.writerow([self._repo_name, 0,
                                     self._nonflaky_test_authors / (
                                                 len(self._test_cases) - (len(self._flaky_testcases) - 1))])
            else:
                if (self._flaky_test_authors/(len(self._flaky_testcases)-1)) < (self._nonflaky_test_authors/(len(self._test_cases)-(len(self._flaky_testcases)-1))):
                    csvdirectory = os.path.join(csvdirectory, "lessflakyauthors/")
                elif (self._flaky_test_authors/(len(self._flaky_testcases)-1)) > (self._nonflaky_test_authors/(len(self._test_cases)-(len(self._flaky_testcases)-1))):
                    csvdirectory = os.path.join(csvdirectory, "moreflakyauthors/")
                else:
                    csvdirectory = os.path.join(csvdirectory, "samenumberofauthors/")
                csvdirectory = os.path.join(csvdirectory, self._repo_name + ".csv")
                with open(csvdirectory, "w") as fd:
                    writer = csv.writer(fd, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
                    writer.writerow([self._repo_name, self._flaky_test_authors/(len(self._flaky_testcases)-1), self._nonflaky_test_authors/(len(self._test_cases)-(len(self._flaky_testcases)-1))])

    @staticmethod
    def _create_parser() -> argparse.ArgumentParser:
        parser = argparse.ArgumentParser(
            fromfile_prefix_chars="@",
            description="""
            An analysing tool for finding authors of tests in python.
            """,
        )

        parser.add_argument("-l", "--logfile", dest="logfile", help="Path to log file.")
        parser.add_argument(
            "-r",
            "--repository",
            dest="repository",
            help="A path to a folder containing the checked-out version of the "
            "repository.",
            required=True,
        )
        parser.add_argument(
            "-u",
            "--url",
            dest="url",
            help="Path to the temp directory",
            required=True,
        )
        parser.add_argument(
            "-o",
            "--output",
            dest="output",
            required=True,
            help="Optional path to an output file.",
        )
        parser.add_argument(
            "-a",
            "--analysisdirectory",
            dest="analysisdir",
            required=False,
            help="Optional path to an output csv file.",
        )
        parser.add_argument(
            "-t"
            "--testlinedirectory",
            dest="tldir",
            required=False,
            help="Optional path to an output csv file with test line numbers.",
        )

        return parser

    def _configure_logger(self) -> logging.Logger:
        logger = logging.getLogger("AuthorAnalyser")
        logger.setLevel(logging.DEBUG)

        if self._config.logfile:
            file = self._config.logfile
        else:
            file = os.path.join(os.path.dirname("__file__"), "testauthor-analysis.log")

        log_file = logging.FileHandler(file)
        log_file.setFormatter(
            logging.Formatter(
                "%(asctime)s [%(levelname)s](%(name)s:%(funcName)s:%(lineno)d: "
                "%(message)s"
            )
        )
        log_file.setLevel(logging.DEBUG)
        logger.addHandler(log_file)

        console = logging.StreamHandler()
        console.setLevel(logging.INFO)
        console.setFormatter(
            logging.Formatter("[%(levelname)s](%(name)s): %(message)s")
        )
        logger.addHandler(console)

        return logger
