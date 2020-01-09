import csv
import importlib

import inspect
import os

def pytest_addoption(parser):
    testplan = parser.getgroup("testplan")
    testplan.addoption("--testplan",
                       action="store",
                       default=None,
                       help="Csv mit test Zeilennummern."
    )
    testplan = parser.getgroup("projectname")
    testplan.addoption("--projectname",
                       action="store",
                       default=None,
                       help="Name des Projektes."
                       )

def pytest_collection_modifyitems(session, config, items):
    path = config.getoption("testplan")
    print(config.getoption("projectname"))
    if path:
        for item in items:
            modulepath = str(os.path.relpath(item.fspath)).split('.')[0].replace("/", ".")
            module = importlib.import_module(modulepath)
            classes = inspect.getmembers(module,
                                     lambda member: inspect.isclass(member) and member.__module__ == module.__name__)
            klaas = module
            if len(classes) >= 1:
                for klasse in classes:
                    tempmethood = getattr(klasse.__getitem__(1), item.name, None)
                    if callable(tempmethood):
                        klaas = klasse.__getitem__(1)
                        break
            itemname = item.name.split("[")[0]
            methood = getattr(klaas, itemname)
            lines, line_start = inspect.getsourcelines(methood)
            temppath = os.path.join(path, "{}.csv".format(config.getoption("projectname")))
            with open(temppath, mode="a") as fd:
                writer = csv.writer(fd, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
                print(klaas.__name__)
                if klaas.__name__ == module.__name__:
                    writer.writerow([module.__name__ + "." + methood.__name__, line_start, line_start + len(lines) - 1])
                else:
                    writer.writerow([module.__name__ + "." + klaas.__name__ + "." + methood.__name__, line_start, line_start + len(lines) - 1])
            print(methood, "Lines:", line_start, line_start + len(lines) - 1)