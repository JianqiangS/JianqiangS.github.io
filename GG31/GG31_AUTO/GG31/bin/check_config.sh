#!/bin/bash
SOURCE_PATH=/home/worker/GG31
source ${SOURCE_PATH}/etc/common.sh

unit_tx2i_enable(){
	# config.json enable tx2i unit
	cat ${SOURCE_PATH}/config.json |
		jq 'to_entries |
			map(if .key == "switch_tx2i"
				then . + {"value":1}
				else .
				end
			) |
		from_entries' > ${SOURCE_PATH}/config.json.bak
	mv ${SOURCE_PATH}/config.json.bak ${SOURCE_PATH}/config.json
}

unit_tx2i_disable(){
	# config.json disable tx2i unit
	cat ${SOURCE_PATH}/config.json |
		jq 'to_entries |
			map(if .key == "switch_tx2i"
				then . + {"value":0}
				else .
				end
			) |
		from_entries' > ${SOURCE_PATH}/config.json.bak
	mv ${SOURCE_PATH}/config.json.bak ${SOURCE_PATH}/config.json
}

unit_net_enable(){
	# config.json enable net unit
	cat ${SOURCE_PATH}/config.json |
		jq 'to_entries |
			map(if .key == "switch_net"
				then . + {"value":1}
				else .
				end
			) |
		from_entries' > ${SOURCE_PATH}/config.json.bak
	mv ${SOURCE_PATH}/config.json.bak ${SOURCE_PATH}/config.json
}

unit_net_disable(){
	# config.json disable net unit
	cat ${SOURCE_PATH}/config.json |
		jq 'to_entries |
			map(if .key == "switch_net"
				then . + {"value":0}
				else .
				end
			) |
		from_entries' > ${SOURCE_PATH}/config.json.bak
	mv ${SOURCE_PATH}/config.json.bak ${SOURCE_PATH}/config.json
}

unit_apu_enable(){
	# config.json enable apu unit
	cat ${SOURCE_PATH}/config.json |
		jq 'to_entries |
			map(if .key == "switch_apu"
				then . + {"value":1}
				else .
				end
			) |
		from_entries' > ${SOURCE_PATH}/config.json.bak
	mv ${SOURCE_PATH}/config.json.bak ${SOURCE_PATH}/config.json
}

unit_apu_disable(){
	# config.json disable apu unit
	cat ${SOURCE_PATH}/config.json |
		jq 'to_entries |
			map(if .key == "switch_apu"
				then . + {"value":0}
				else .
				end
			) |
		from_entries' > ${SOURCE_PATH}/config.json.bak
	mv ${SOURCE_PATH}/config.json.bak ${SOURCE_PATH}/config.json
}

unit_cdu_enable(){
	# config.json enable cdu unit
	cat ${SOURCE_PATH}/config.json |
		jq 'to_entries |
			map(if .key == "switch_cdu"
				then . + {"value":1}
				else .
				end
			) |
		from_entries' > ${SOURCE_PATH}/config.json.bak
	mv ${SOURCE_PATH}/config.json.bak ${SOURCE_PATH}/config.json
}

unit_cdu_disable(){
	# config.json disable cdu unit
	cat ${SOURCE_PATH}/config.json |
		jq 'to_entries |
			map(if .key == "switch_cdu"
				then . + {"value":0}
				else .
				end
			) |
		from_entries' > ${SOURCE_PATH}/config.json.bak
	mv ${SOURCE_PATH}/config.json.bak ${SOURCE_PATH}/config.json
}

unit_ioin_enable(){
	# config.json enable ioin unit
	cat ${SOURCE_PATH}/config.json |
		jq 'to_entries |
			map(if .key == "switch_ioin"
				then . + {"value":1}
				else .
				end
			) |
		from_entries' > ${SOURCE_PATH}/config.json.bak
	mv ${SOURCE_PATH}/config.json.bak ${SOURCE_PATH}/config.json
}

unit_ioin_disable(){
	# config.json disable ioin unit
	cat ${SOURCE_PATH}/config.json |
		jq 'to_entries |
			map(if .key == "switch_ioin"
				then . + {"value":0}
				else .
				end
			) |
		from_entries' > ${SOURCE_PATH}/config.json.bak
	mv ${SOURCE_PATH}/config.json.bak ${SOURCE_PATH}/config.json
}

unit_ioout_enable(){
	# config.json enable ioout unit
	cat ${SOURCE_PATH}/config.json |
		jq 'to_entries |
			map(if .key == "switch_ioout"
				then . + {"value":1}
				else .
				end
			) |
		from_entries' > ${SOURCE_PATH}/config.json.bak
	mv ${SOURCE_PATH}/config.json.bak ${SOURCE_PATH}/config.json
}

unit_ioout_disable(){
	# config.json disable ioout unit
	cat ${SOURCE_PATH}/config.json |
		jq 'to_entries |
			map(if .key == "switch_ioout"
				then . + {"value":0}
				else .
				end
			) |
		from_entries' > ${SOURCE_PATH}/config.json.bak
	mv ${SOURCE_PATH}/config.json.bak ${SOURCE_PATH}/config.json
}

unit_dgps_enable(){
	# config.json enable dgps unit
	cat ${SOURCE_PATH}/config.json |
		jq 'to_entries |
			map(if .key == "switch_dgps"
				then . + {"value":1}
				else .
				end
			) |
		from_entries' > ${SOURCE_PATH}/config.json.bak
	mv ${SOURCE_PATH}/config.json.bak ${SOURCE_PATH}/config.json
}

unit_dgps_disable(){
	# config.json disable dgps unit
	cat ${SOURCE_PATH}/config.json |
		jq 'to_entries |
			map(if .key == "switch_dgps"
				then . + {"value":0}
				else .
				end
			) |
		from_entries' > ${SOURCE_PATH}/config.json.bak
	mv ${SOURCE_PATH}/config.json.bak ${SOURCE_PATH}/config.json
}

unit_bb_enable(){
	# config.json enable bb unit
	cat ${SOURCE_PATH}/config.json |
		jq 'to_entries |
			map(if .key == "switch_bb"
				then . + {"value":1}
				else .
				end
			) |
		from_entries' > ${SOURCE_PATH}/config.json.bak
	mv ${SOURCE_PATH}/config.json.bak ${SOURCE_PATH}/config.json
}

unit_bb_disable(){
	# config.json disable bb unit
	cat ${SOURCE_PATH}/config.json |
		jq 'to_entries |
			map(if .key == "switch_bb"
				then . + {"value":0}
				else .
				end
			) |
		from_entries' > ${SOURCE_PATH}/config.json.bak
	mv ${SOURCE_PATH}/config.json.bak ${SOURCE_PATH}/config.json
}

unit_ota_enable(){
	# config.json enable ota unit
	cat ${SOURCE_PATH}/config.json |
		jq 'to_entries |
			map(if .key == "switch_ota"
				then . + {"value":1}
				else .
				end
			) |
		from_entries' > ${SOURCE_PATH}/config.json.bak
	mv ${SOURCE_PATH}/config.json.bak ${SOURCE_PATH}/config.json
}

unit_ota_disable(){
	# config.json disable ota unit
	cat ${SOURCE_PATH}/config.json |
		jq 'to_entries |
			map(if .key == "switch_ota"
				then . + {"value":0}
				else .
				end
			) |
		from_entries' > ${SOURCE_PATH}/config.json.bak
	mv ${SOURCE_PATH}/config.json.bak ${SOURCE_PATH}/config.json
}

unit_power_enable(){
	# config.json enable power unit
	cat ${SOURCE_PATH}/config.json |
		jq 'to_entries |
			map(if .key == "switch_power"
				then . + {"value":1}
				else .
				end
			) |
		from_entries' > ${SOURCE_PATH}/config.json.bak
	mv ${SOURCE_PATH}/config.json.bak ${SOURCE_PATH}/config.json
}

unit_power_disable(){
	# config.json disable power unit
	cat ${SOURCE_PATH}/config.json |
		jq 'to_entries |
			map(if .key == "switch_power"
				then . + {"value":0}
				else .
				end
			) |
		from_entries' > ${SOURCE_PATH}/config.json.bak
	mv ${SOURCE_PATH}/config.json.bak ${SOURCE_PATH}/config.json
}

unit_config_check(){
	chmod +x ${SOURCE_PATH}/config.json
}

unit_disable_all(){
	# disable all unit config
	unit_tx2i_disable
	unit_net_disable
	unit_apu_disable
	unit_cdu_disable
	unit_ioin_disable
	unit_ioout_disable
	unit_dgps_disable
	unit_bb_disable
	unit_ota_disable
	unit_power_disable
	unit_config_check
}

unit_enable_all(){
	# enable all unit config
	unit_tx2i_enable
	unit_net_enable
	unit_apu_enable
	unit_cdu_enable
	unit_ioin_enable
	unit_ioout_enable
	unit_dgps_enable
	unit_bb_enable
	unit_ota_enable
	unit_power_enable
	unit_config_check
}
