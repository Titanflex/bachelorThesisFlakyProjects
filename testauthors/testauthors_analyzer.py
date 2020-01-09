import sys

from testauthors.analyzer import Analyzer

if __name__ == "__main__":
    analyser = Analyzer(sys.argv)
    analyser.run()