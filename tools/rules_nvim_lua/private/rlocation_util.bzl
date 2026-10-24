def get_rlocation_path(file):
    runfile_path = file.short_path
    if runfile_path.startswith("../"):
        return runfile_path[3:]
    else:
        return "_main" + "/" + runfile_path
