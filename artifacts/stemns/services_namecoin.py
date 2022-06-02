import os

import __main__
stemns_dir = os.path.dirname(os.path.realpath(__main__.__file__))
bin_base = stemns_dir
app_base = os.path.dirname(bin_base)

ncprop279 = bin_base + "/ncprop279"
conf = app_base + "/etc_ncprop279/ncprop279.conf"
cmd = [ncprop279, "-conf=" + conf]

service_to_command = {
    "bit.onion": cmd,
    "bit": cmd,
}
