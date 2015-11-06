#!/usr/bin/python
#############################################################################
# ITweb <-> Spacewalk Integration                                           #
# queries all spacewalk machines, and looks up their location and pcnum     #
# from itweb.                                                               #
# Written for STL by Matt Ruge <matt.ruge@gtri.gatech.edu>                  #
#############################################################################
#### Imports ##################################################################
import xmlrpclib
import getpass
import os
import subprocess
import simplejson as json
import pycurl
import StringIO
import optparse

def get_options():
    usage = "%prog [--verbose]"
    parser = optparse.OptionParser(usage=usage)
    parser.add_option("--debug", "-d", dest="debug", action="store_true",
                      default=False, help="Debug Mode")
    parser.add_option("--verbose", "-v", dest="verbose", action="store_true",
                      default=False, help="Enable output")
    parser.add_option("--force", "-f", dest="update", action="store_true",
                      default=False, help="Force update of sw data")
    parser.add_option("--cert", action="store" , type="string",
                  dest="cert", default="/etc/pki/tls/certs/gripper.crt",
                  help="machine certificate", metavar="PATH")
    parser.add_option("--ca", action="store" , type="string",
                  dest="ca", default="/etc/pki/tls/certs/gtri-bundle.crt",
                  help="certificate authority", metavar="PATH")
    parser.add_option("--key", action="store" , type="string",
                  dest="key", default="/etc/pki/tls/private/gripper.key",
                  help="machine key", metavar="PATH")
    parser.add_option("--figlet", action="store" , type="string",
                  dest="figlet", default="/usr/bin/figlet",
                  help="machine key", metavar="PATH")

    (options, args) = parser.parse_args()
    return options, args

def main():
    options, args = get_options()
    #### Checking environment #####################################################
    asciiart=True
    if not os.path.exists(options.figlet):
        asciiart=False
        print "Figlet doesn't seem to be installed disableing ascii art"


    #### Running variables ########################################################
    method="json"
    debug=options.debug
    run_only_pc=[1000010120,1000010020,1000010642,1000010632]

    #### USE PCDB #################################################################
    if method == "db":
        dbhost="localhost"
        dbuser="root"
        dbpass=""
        dbname="intranet"
        db=_mysql.connect(dbhost,dbuser,dbpass,dbname)
        db.query("select pna.pcNum, pna.IP, pcb.location \
                    from pcnetworkassignments pna, pcbasic pcb;")
        r=db.store_result()
        test=[]
        for i in range(r.num_rows()):
            test+=r.fetch_row()

        test2=filter(lambda item: item[1] is not None, test)
        test3 = map(lambda item: (item[1],item[0]), test2)
        d=dict(test3)

    #### USE ITWEB JSON ###########################################################
    if method == "json":
        itweb_sw_url="https://itweb/pcdetails/spaceWalkConnector"
	itweb_sw_file = StringIO.StringIO()
	curl = pycurl.Curl()
	curl.setopt(pycurl.CAINFO, options.ca)
	curl.setopt(pycurl.SSLCERT, options.cert)
	curl.setopt(pycurl.SSLKEY, options.key)
	curl.setopt(pycurl.SSL_VERIFYPEER, False)
	curl.setopt(pycurl.SSL_VERIFYHOST, 2)
	curl.setopt(pycurl.URL, itweb_sw_url)
	curl.setopt(pycurl.WRITEFUNCTION, itweb_sw_file.write)
	curl.perform()
	itweb_sw_file.seek(0)
        itweb_sw_json=json.loads(itweb_sw_file.read())
        json_dict={}

        for i in range(len(itweb_sw_json["spacewalk"][0])):
            itweb_pc=itweb_sw_json["spacewalk"][0][i]
            json_dict[ itweb_pc['ip'] ] = (
                    itweb_pc['pcnum'],
                    itweb_pc['location'],
                    itweb_pc['hostname'],
                    itweb_pc['user'])

    #### SPACEWALK CONNECTION #####################################################
    spacewalk_url = "https://spacewalk/rpc/api"
    SATELLITE_LOGIN = "autobot"
    SATELLITE_PASSWORD = "U4g2PBYkv5rGxtdwT2uCsp+ImGkum87z"

    try:
        client = xmlrpclib.Server(spacewalk_url, verbose=0)
        key = client.auth.login(SATELLITE_LOGIN, SATELLITE_PASSWORD)
    except:
        print "CANNOT CONNECT TO SPACEWALK"
        exit()
    #### List SW Systems ##########################################################
    sw_systems=client.system.listSystems(key)
    if options.verbose:
        print "Updating "+str(len(sw_systems))+" Systems"
    count = len(sw_systems)
    for sw_system in sw_systems:
        sw_id=sw_system['id']
        if (sw_id in run_only_pc) or not debug:
            try:
		#### Clear Variables ###############################################
		json_pcnum=""
		sw_hw_info=""
		ascii_output=""
		building=""
		room=""

                sw_net=client.system.getNetwork(key, sw_id)

                #### Hostname ######################################################
                sw_hostname=sw_net['hostname'].split(".")[0]

                #### IP ############################################################
                sw_ip=sw_net['ip']

                #### CPU ###########################################################
                try:
                    sw_cpu_all=client.system.getCpu(key, sw_id)
                    sw_cpu=sw_cpu_all['arch']+" - "+sw_cpu_all['model']
                except:
                    sw_cpu="Unknown CPU"

                #### Memory ########################################################
                try:
                    sw_mem=client.system.getMemory(key, sw_id)['ram']
                except:
                    sw_mem="Unknown Memory"

                #### ITWEB INFO ####################################################
                json_system=json_dict.get(sw_ip)

                #### Location ######################################################
                if json_system is not None:
                    json_location = json_dict.get(sw_ip)[1]

                #### PCNumber#######################################################
                if json_system is not None:
                    json_pcnum = json_dict.get(sw_ip)[0]
                
                
                if json_pcnum is not None and json_location is not None:
                    #### BREAK LOCATION INTO BUILDING AND ROOM #####################
                    json_location_arr=json_location.split(" ")
                    if len(json_location_arr) > 1:
                        building=json_location_arr[0]
                    room=json_location_arr[-1]
                    
                    #### MAKE ASCII ART ############################################
                    if asciiart:
                        ascii_output="-------------------------------------------------------------------------------\n"
                        p=subprocess.Popen(
                            [options.figlet,sw_hostname],
                            stdout=subprocess.PIPE)
                        ascii_output+=p.communicate()[0]
                        ascii_output+="-------------------------------------------------------------------------------\n"

                    #### MAKE HARDWARE INFO ########################################
                    sw_hw_info=""
                    sw_hw_info+="CPU: \t\t"+sw_cpu+"\n"
                    sw_hw_info+="Memory: \t"+str(sw_mem)+"MB"

                    #### DEBUG PRINT ###############################################
                    if debug:
                        print ascii_output
                        print "PCNUM: "+json_pcnum                
                        print "sw_hw_info: \n"+sw_hw_info
                        print "Building: "+building+" Room: "+room          

                    #### UPDATE SPACEWALK ##########################################
                    if not debug:
                        sw_cur_data=client.system.getCustomValues(key,sw_id)
                        if sw_cur_data.get('PCNum') != json_pcnum:
                            client.system.setCustomValues(key, sw_id,
                                {'PCNum':json_pcnum})
                        if sw_cur_data.get('hardware_info') != sw_hw_info:
                            client.system.setCustomValues(key, sw_id,
                                {'hardware_info':sw_hw_info})
                        if (len(sw_cur_data.get('ascii_hostname',"")) < 20  and asciiart):
                            client.system.setCustomValues(key, sw_id, 
                                {'ascii_hostname':ascii_output})
			#client.system.setCustomValues(key, sw_id,{'ascii_hostname':ascii_output})
                        sw_cur_location=client.system.getDetails(key, sw_id)
                        if (sw_cur_location.get('building') != building 
                        or sw_cur_location.get('room') != room):
                            client.system.setDetails(key, sw_id,
                                {'building':building,'room':room})
                count-=1
                if options.verbose:
                    print count, "machines left________________________________________"                
            except (KeyboardInterrupt, SystemExit):
                print "Quitting the program"  
                break          
            except:
                if options.verbose:
                    print 'Could not parse data for Spacewalk ID '+str(sw_id)
		if debug:
	                raise
                pass
    client.auth.logout(key)

if __name__ == "__main__":
    main()
