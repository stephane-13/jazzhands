-- Copyright (c) 2005-2010, Vonage Holdings Corp.
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
--     * Redistributions of source code must retain the above copyright
--       notice, this list of conditions and the following disclaimer.
--     * Redistributions in binary form must reproduce the above copyright
--       notice, this list of conditions and the following disclaimer in the
--       documentation and/or other materials provided with the distribution.
--
-- THIS SOFTWARE IS PROVIDED BY VONAGE HOLDINGS CORP. ''AS IS'' AND ANY
-- EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL VONAGE HOLDINGS CORP. BE LIABLE FOR ANY
-- DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
/*
 * $Id$
 */
create or replace package body port_utils
IS
	-------------------------------------------------------------------
	-- returns the Id tag for CM
	-------------------------------------------------------------------
	FUNCTION id_tag
	RETURN VARCHAR2
	IS
	BEGIN
     		RETURN('<-- $Id$ -->');
	END;
	--end of procedure id_tag
	-------------------------------------------------------------------

	-------------------------------------------------------------------
	-- sets up power ports for a device if they are not there.
	-------------------------------------------------------------------
	PROCEDURE setup_device_power (
		in_Device_id device.device_id%type
	)
	IS
		dt_id	device.device_type_id%type;
	BEGIN
		if( port_support.has_power_ports(in_device_id) ) then
			return;
		end if;

		select  device_type_id
		  into	dt_id
		  from  device
		 where	device_id = in_device_id;

		 insert into device_power_interface
			(device_id, power_interface_port)
			select in_device_id, power_interface_port
			  from device_type_power_port_templt
			 where device_type_id = dt_id;
	END;

	-------------------------------------------------------------------
	-- sets up serial ports for a device if they are not there.
	-------------------------------------------------------------------
	PROCEDURE setup_device_serial (
		in_Device_id device.device_id%type
	)
	IS
		dt_id	device.device_type_id%type;
	BEGIN
		setup_device_physical_ports(in_device_id, 'serial');
	END;

	-------------------------------------------------------------------
	-- sets up physical ports for a device if they are not there.  This
	-- will eitehr use in_port_type or in the case where its not set,
	-- will iterate over each type of physical port and run it for that.
	-- This is to facilitate new types that show up over time.
	-------------------------------------------------------------------
	PROCEDURE setup_device_physical_ports (
		in_Device_id device.device_id%type,
		in_port_type val_port_type.port_type%type DEFAULT NULL
	)
	IS
		v_dt_id	device.device_type_id%type;
		v_pt	val_port_type.port_type%type;
		CURSOR	ptypes IS
			select port_type from val_port_type;
	BEGIN
		select  device_type_id
		  into	v_dt_id
		  from  device
		 where	device_id = in_device_id;

		OPEN ptypes;
		LOOP
			FETCH ptypes INTO v_pt;
			EXIT WHEN ptypes%NOTFOUND;
			if(in_port_type is NULL or v_pt = in_port_type) THEN
				if( NOT port_support.has_physical_ports(in_device_id,v_pt) ) then
					insert into physical_port
						(device_id, port_name, port_type)
						select	in_device_id, port_name, port_type
						  from	device_type_phys_port_templt
						 where  device_type_id = v_dt_id
						  and	port_type = v_pt
					;
				end if;
			end if;
		END LOOP;
	END;

	-------------------------------------------------------------------
	-- connect to layer1 devices
	-------------------------------------------------------------------
	--
	-- XXX need to setup out variable
	--
	FUNCTION configure_layer1_connect (
		physportid1	physical_port.physical_port_id%type,
		physportid2	physical_port.physical_port_id%type,
		baud		layer1_connection.baud%type			DEFAULT -99,
		data_bits	layer1_connection.data_bits%type	DEFAULT -99,
		stop_bits	layer1_connection.stop_bits%type	DEFAULT -99,
		parity     	layer1_connection.parity%type		DEFAULT '__unknown__',
		flw_cntrl	layer1_connection.flow_control%type DEFAULT '__unknown__',
		circuit_id   	layer1_connection.circuit_id%type DEFAULT -99
	) RETURN number
	IS
		tally		number;
		l1_con_id	layer1_connection.layer1_connection_id%TYPE;
		l1con		layer1_connection%ROWTYPE;
		p1_l1_con	layer1_connection%ROWTYPE;
		p2_l1_con	layer1_connection%ROWTYPE;
		p1_port		physical_port%ROWTYPE;
		p2_port		physical_port%ROWTYPE;
		col_nams	port_support.layer1_conn_array;
		col_vals	port_support.layer1_conn_array;
		updateitr	number;
		i_baud		layer1_connection.baud%type;
		i_data_bits	layer1_connection.data_bits%type;
		i_stop_bits	layer1_connection.stop_bits%type;
		i_parity     	layer1_connection.parity%type;
		i_flw_cntrl	layer1_connection.flow_control%type;
		i_circuit_id layer1_connection.circuit_id%type;
	BEGIN
		dbms_output.put_line('looking up ' || physportid1 ||
			' and ' || physportid2 );

		dbms_output.put_line('min args ' || physportid1 || ':' ||
			physportid2 || ':' || circuit_id || '<--' );

		-- First make sure the physical ports exist
		-- [XXX] probably want to pull out into a cursor
		BEGIN
			select	*
			  into	p1_port
			  from	physical_port
			 where	physical_port_id = physportid1;
	
			select	*
			  into	p2_port
			  from	physical_port
			 where	physical_port_id = physportid2;
		EXCEPTION WHEN no_data_found THEN
			raise_application_error(-20100, 'Two physical Ports Must be Specified');
		END;

		if p1_port.port_type <> p2_port.port_type then
			raise_application_error(-20101, 'port types must match');
		end if;
	
		-- see if existing layer1_connection exists
		-- [XXX] probably want to pull out into a cursor
		BEGIN
			select	*
			  into	p1_l1_con
			  from	layer1_connection
			 where	physical_port1_id = physportid1
			    or  physical_port2_id = physportid1;
		EXCEPTION WHEN no_data_found THEN
			NULL;
		END;
		BEGIN
			select	*
			  into	p2_l1_con
			  from	layer1_connection
			 where	physical_port1_id = physportid2
			    or  physical_port2_id = physportid2;
		
		EXCEPTION WHEN no_data_found THEN
			NULL;
		END;

		updateitr := 0;

		--		need to figure out which ports to reset in some cases
		--		need to check as many combinations as possible.
		--		need to deal with new ids.

		--
		-- If a connection already exists, figure out the right one
		-- If there are two, then remove one.  Favor ones where the left
		-- is this port.
		--
		-- Also falling out of this will be the port needs to be updated,
		-- assuming a port needs to be updated
		--
		dbms_output.put_line('one is ' || p1_l1_con.layer1_connection_id ||
			' the other is ' || p2_l1_con.layer1_connection_id);
		if (p1_l1_con.layer1_connection_id is not NULL) then
			if (p2_l1_con.layer1_connection_id is not NULL) then
				if (p1_l1_con.physical_port1_id = physportid1) then
					--
					-- if this is not true, then the connection already
					-- exists between these two, and layer1_params need to
					-- be set later.  If they are already connected,
					-- this gets discovered here
					--
					if(p1_l1_con.physical_port2_id != physportid2) then
						--
						-- physport1 is connected to something, just not this
						--
						dbms_output.put_line(' physport1 is connected to something, just not this');
						l1_con_id := p1_l1_con.layer1_connection_id;
						--
						-- physport2 is connected to something, which needs to go away, so make it go away
						--
						if(p2_l1_con.layer1_connection_id is not NULL) then
							dbms_output.put_line(' physport2 is connected to something, deleting it');
							dbms_output.put_line('>>>> removing' || p2_l1_con.layer1_connection_id);
							delete from layer1_connection
								where layer1_connection_id =
									p2_l1_con.layer1_connection_id;
						end if;
					else
						l1_con_id := p1_l1_con.layer1_connection_id;
						dbms_output.put_line('they''re already connected');
					end if;
				elsif (p1_l1_con.physical_port2_id = physportid1) then
					dbms_output.put_line('>>> connection is backwards!');
					if (p1_l1_con.physical_port1_id != physportid2) then
						if (p2_l1_con.physical_port1_id = physportid1) then
							l1_con_id := p2_l1_con.layer1_connection_id;
							dbms_output.put_line('>>>> removing' || p1_l1_con.layer1_connection_id);
							delete from layer1_connection
								where layer1_connection_id =
									p1_l1_con.layer1_connection_id;
						else
							if (p1_l1_con.physical_port1_id = physportid1) then
								l1_con_id := p1_l1_con.layer1_connection_id;
							else
								-- p1_l1_con.physical_port2_id must be physportid1
								l1_con_id := p1_l1_con.layer1_connection_id;
							end if;
							dbms_output.put_line('>>>> removing' || p2_l1_con.layer1_connection_id);
							delete from layer1_connection
								where layer1_connection_id =
									p2_l1_con.layer1_connection_id;
						end if;
					else
						dbms_output.put_line('they''re already connected, but backwards');
						l1_con_id := p1_l1_con.layer1_connection_id;
					end if;
				end if;
			else
				dbms_output.put_line('p1 is connected, but p2 is not');
				l1_con_id := p1_l1_con.layer1_connection_id;
			end if;
		elsif(p2_l1_con.layer1_connection_id is NULL) then
			-- both are null in this case
				
			IF (circuit_id = -99) THEN
				i_circuit_id := NULL;
			ELSE
				i_circuit_id := circuit_id;
			END IF;
			IF (baud = -99) THEN
				i_baud := NULL;
			ELSE
				i_baud := baud;
			END IF;
			IF data_bits = -99 THEN
				i_data_bits := NULL;
			ELSE
				i_data_bits := data_bits;
			END IF;
			IF stop_bits = -99 THEN
				i_stop_bits := NULL;
			ELSE
				i_stop_bits := stop_bits;
			END IF;
			IF parity = '__unknown__' THEN
				i_parity := NULL;
			ELSE
				i_parity := parity;
			END IF;
			IF flw_cntrl = '__unknown__' THEN
				i_flw_cntrl := NULL;
			ELSE
				i_flw_cntrl := flw_cntrl;
			END IF;
			IF p1_port.port_type = 'serial' THEN
			        insert into layer1_connection (
				        PHYSICAL_PORT1_ID, PHYSICAL_PORT2_ID,
				        BAUD, DATA_BITS, STOP_BITS, PARITY, FLOW_CONTROL, 
				        CIRCUIT_ID, IS_TCPSRV_ENABLED
			        ) values (
				        physportid1, physportid2,
				        i_baud, i_data_bits, i_stop_bits, i_parity, i_flw_cntrl,
				        i_circuit_id, 'Y'
			        ) returning layer1_connection_id into l1_con_id;
			ELSE
			        insert into layer1_connection (
				        PHYSICAL_PORT1_ID, PHYSICAL_PORT2_ID,
				        BAUD, DATA_BITS, STOP_BITS, PARITY, FLOW_CONTROL, 
				        CIRCUIT_ID
			        ) values (
				        physportid1, physportid2,
				        i_baud, i_data_bits, i_stop_bits, i_parity, i_flw_cntrl,
				        i_circuit_id
			        ) returning layer1_connection_id into l1_con_id;
			END IF;
			dbms_output.put_line('added, l1_con_id is ' || l1_con_id);
			return 1;
		else
			dbms_output.put_line('p2 is not connected, but p1 is');
			l1_con_id := p2_l1_con.layer1_connection_id;
		end if;

		dbms_output.put_line('l1_con_id is ' || l1_con_id);

		-- check to see if both ends are the same type
		-- see if they're already connected.  If not, zap the connection
		--	that doesn't match this port1/port2 config (favor first port)
		-- update various variables
		select	*
		  into	l1con
		  from	layer1_connection
		 where	layer1_connection_id = l1_con_id;

		if (l1con.PHYSICAL_PORT1_ID != physportid1 OR
				l1con.PHYSICAL_PORT2_ID != physportid2) AND
				(l1con.PHYSICAL_PORT1_ID != physportid2 OR
				l1con.PHYSICAL_PORT2_ID != physportid1)  THEN
			-- this means that one end is wrong.
			if(l1con.PHYSICAL_PORT1_ID = physportid1) THEN
				dbms_output.put_line('update port2 to second port');
				updateitr := updateitr + 1;
				col_nams(updateitr) := 'PHYSICAL_PORT2_ID';
				col_vals(updateitr) := physportid2;
			elsif(l1con.PHYSICAL_PORT2_ID = physportid1) THEN
				dbms_output.put_line('update port1 to second port');
				updateitr := updateitr + 1;
				col_nams(updateitr) := 'PHYSICAL_PORT1_ID';
				col_vals(updateitr) := physportid2;
			elsif(l1con.PHYSICAL_PORT1_ID = physportid2) THEN
				dbms_output.put_line('update port2 to first port');
				updateitr := updateitr + 1;
				col_nams(updateitr) := 'PHYSICAL_PORT2_ID';
				col_vals(updateitr) := physportid1;
			elsif(l1con.PHYSICAL_PORT2_ID = physportid2) THEN
				dbms_output.put_line('update port1 to first port');
				updateitr := updateitr + 1;
				col_nams(updateitr) := 'PHYSICAL_PORT1_ID';
				col_vals(updateitr) := physportid1;
			end if;
		end if;

		dbms_output.put_line(circuit_id || ' circuit_id v ' || l1con.circuit_id);
		if(circuit_id <> -99 and (l1con.circuit_id is NULL or l1con.circuit_id <> circuit_id)) THEN
			dbms_output.put_line('updating circuit_id');
			updateitr := updateitr + 1;
			col_nams(updateitr) := 'CIRCUIT_ID';
			col_vals(updateitr) := circuit_id;
		end if;

		dbms_output.put_line(baud || ' baud v ' || l1con.baud);
		if(baud <> -99 and (l1con.baud is NULL or l1con.baud <> baud)) THEN
			dbms_output.put_line('updating baud');
			updateitr := updateitr + 1;
			col_nams(updateitr) := 'BAUD';
			col_vals(updateitr) := baud;
		end if;

		if(data_bits <> -99 and (l1con.data_bits is NULL or l1con.data_bits <> data_bits)) THEN
			dbms_output.put_line('updating data_bits');
			updateitr := updateitr + 1;
			col_nams(updateitr) := 'DATA_BITS';
			col_vals(updateitr) := data_bits;
		end if;

		if(stop_bits <> -99 and (l1con.stop_bits is NULL or l1con.stop_bits <> stop_bits)) THEN
			dbms_output.put_line('updating stop_bits');
			updateitr := updateitr + 1;
			col_nams(updateitr) := 'STOP_BITS';
			col_vals(updateitr) := stop_bits;
		end if;

		if(parity <> '__unknown__' and (l1con.parity is NULL or l1con.parity <> parity)) THEN
			dbms_output.put_line('updating data_bits');
			updateitr := updateitr + 1;
			col_nams(updateitr) := 'PARITY';
			col_vals(updateitr) := parity;
		end if;

		if(flw_cntrl <> '__unknown__' and (l1con.parity is NULL or l1con.parity <> flw_cntrl)) THEN
			dbms_output.put_line('updating flw_control');
			updateitr := updateitr + 1;
			col_nams(updateitr) := 'FLOW_CONTROL';
			col_vals(updateitr) := flw_cntrl;
		end if;

		if(updateitr > 0) then
			dbms_output.put_line('running do_l1_connection_update');
			port_support.do_l1_connection_update(col_nams, col_vals, l1_con_id);
		end if;

	dbms_output.put_line('returning ' || updateitr);
	return updateitr;
	END;

	-------------------------------------------------------------------
	-- connect two power devices
	-------------------------------------------------------------------
	FUNCTION configure_power_connect (
		in_dev1_id	device_power_connection.device_id%type,
		in_port1_id	device_power_connection.power_interface_port%type,
		in_dev2_id	device_power_connection.rpc_device_id%type,
		in_port2_id	device_power_connection.rpc_power_interface_port%type
	) return number
	IS
		v_p1_pc		device_power_connection%ROWTYPE;
		v_p2_pc		device_power_connection%ROWTYPE;
		v_pc		device_power_connection%ROWTYPE;
		v_pc_id		device_power_connection.device_power_connection_id%type;
	BEGIN
		dbms_output.put_line('consider ' || in_dev1_id || ':' || in_port1_id || ' ' || in_dev2_id || ':' || in_port2_id);
		-- check to see if ports are already connected
		BEGIN
			select	*
			  into	v_p1_pc
			  from	device_power_connection
			 where	(device_Id = in_dev1_id 
						and power_interface_port = in_port1_id) OR
					(rpc_device_id = in_dev1_id
						and rpc_power_interface_port = in_port1_id);
		EXCEPTION WHEN no_data_found THEN
			v_p1_pc.device_power_connection_id := NULL;
		END;

		BEGIN
			select	*
			  into	v_p2_pc
			  from	device_power_connection
			 where	(device_Id = in_dev2_id 
						and power_interface_port = in_port2_id) OR
					(rpc_device_id = in_dev2_id
						and rpc_power_interface_port = in_port2_id);
		EXCEPTION WHEN no_data_found THEN
			v_p2_pc.device_power_connection_id := NULL;
		END;

		--
		-- If a connection already exists, figure out the right one
		-- If there are two, then remove one.  Favor ones where the left
		-- is this port.
		--
		-- Also falling out of this will be the port needs to be updated,
		-- assuming a port needs to be updated
		--
		dbms_output.put_line('one is ' || v_p1_pc.device_power_connection_id ||
			' the other is ' || v_p2_pc.device_power_connection_id);
		IF (v_p1_pc.device_power_connection_id is not NULL) then
			IF (v_p2_pc.device_power_connection_id is not NULL) then
				IF (v_p1_pc.device_id = in_dev1_id AND v_p1_pc.power_interface_port = in_port1_id) then
					--
					-- if this is not true, then the connection already
					-- exists between these two.
					-- If they are already connected, this gets 
					-- discovered here
					--
					dbms_output.put_line('>> side one matches:' || v_p1_pc.rpc_device_id || ':' || in_dev2_id || 
						' ' || v_p1_pc.rpc_power_interface_port || ':' || in_port2_id);
					IF(v_p1_pc.rpc_device_id != in_dev2_id OR v_p1_pc.rpc_power_interface_port != in_port2_id) then
						--
						-- port is connected to something, just not this
						--
						dbms_output.put_line(' port1 is connected to something, just not this');
						v_pc_id := v_p1_pc.device_power_connection_id;
						--
						-- port2 is connected to something, which needs to go away, so make it go away
						--
						IF(v_p2_pc.device_power_connection_id is not NULL) then
							dbms_output.put_line(' por2 is connected to something, deleting it');
							dbms_output.put_line('>>>> removing(0) ' || v_p2_pc.device_power_connection_id);
							delete from device_power_connection
								where device_power_connection_id =
									v_p2_pc.device_power_connection_id;
						END IF;
					ELSE
						v_pc_id := v_p1_pc.device_power_connection_id;
						dbms_output.put_line('they''re already connected to each other');
						-- XXX NOTE THAT THIS SHOULD NOT RETURN FOR MORE PROPERTIES TO TWEAK
						return 0;
					END IF;
				ELSIF (v_p1_pc.rpc_device_id = in_dev1_id AND v_p1_pc.rpc_power_interface_port = in_port1_id) then
					dbms_output.put_line('>>> connection is backwards!');
					IF(v_p1_pc.device_id != in_dev2_id OR v_p1_pc.power_interface_port != in_port2_id) then
						IF (v_p2_pc.rpc_device_id = in_dev1_id AND v_p2_pc.rpc_power_interface_port = in_port1_id) then
							v_pc_id := v_p2_pc.device_power_connection_id;
							dbms_output.put_line('>>>> removing(1) ' || v_p1_pc.device_power_connection_id);
							delete from device_power_connection
								where device_power_connection_id =
									v_p1_pc.device_power_connection_id;
						ELSE
							IF (v_p1_pc.device_id = in_dev1_id AND v_p1_pc.power_interface_port = in_port1_id) then
								v_pc_id := v_p1_pc.device_power_connection_id;
							ELSE
								-- v_p1_pc.device_id must be port1
								v_pc_id := v_p1_pc.device_power_connection_id;
							END IF;
							dbms_output.put_line('>>>> removing(2) ' || v_p2_pc.device_power_connection_id);
							delete from device_power_connection
								where device_power_connection_id =
									v_p2_pc.device_power_connection_id;
						END IF;
					ELSE
						dbms_output.put_line('they''re already connected, but backwards');
						v_pc_id := v_p1_pc.device_power_connection_id;
						-- XXX NOTE THAT THIS SHOULD NOT RETURN FOR MORE PROPERTIES TO TWEAK
						return 0;
					END IF;
				ELSE
					dbms_output.put_line('else condition that should not have happened happened');
					return 0;
				END IF;
			ELSE
				dbms_output.put_line('p1 is connected, but p2 is not');
				v_pc_id := v_p1_pc.device_power_connection_id;
			END IF;
		ELSIF(v_p2_pc.device_power_connection_id is NULL) then
			-- both are null in this case, so connect 'em.
			dbms_output.put_line('inserting a brand new record!');
			dbms_output.put_line('consider ' || in_dev1_id || ':' || in_port1_id || ' ' || in_dev2_id || ':' || in_port2_id);
			insert into device_power_connection (
				rpc_device_id,
				rpc_power_interface_port,
				power_interface_port,
				device_id
			) values (
				in_dev2_id,
				in_port2_id,
				in_port1_id,
				in_dev1_id 
			);
			dbms_output.put_line('record is totally inserted.');
			return 1;
		ELSE
			dbms_output.put_line('p2 is connected, but p1 is not (else)');
			v_pc_id := v_p2_pc.device_power_connection_id;
		END IF;

		dbms_output.put_line('salvaging power connection ' || v_pc_id);
		-- this is here instead of above so that its possible to add properties
		-- to the argument list that would also get updated the same way serial
		-- port parameters do.  Otherwise, it would make more sense to do the
		-- updates in the morass above.
		--
		select	*
		  into	v_pc
		  from	device_power_connection
		 where	device_power_connection_id = v_pc_id;

		-- XXX - need to actually figure out which part to update and upate it.
		IF v_pc.device_id = in_dev1_id AND v_pc.power_interface_port = in_port1_id THEN
			update	device_power_connection
			   set	rpc_device_id = in_dev2_id,
					rpc_power_interface_port = in_port2_id
			  where	device_power_connection_id = v_pc_id;
		ELSIF v_pc.device_id = in_dev2_id AND v_pc.power_interface_port = in_port2_id THEN
			update	device_power_connection
			   set	rpc_device_id = in_dev1_id,
					rpc_power_interface_port = in_port1_id
			  where	device_power_connection_id = v_pc_id;
		ELSIF v_pc.rpc_device_id = in_dev1_id AND v_pc.rpc_power_interface_port = in_port1_id THEN
			update	device_power_connection
			   set	device_id = in_dev2_id,
					power_interface_port = in_port2_id
			  where	device_power_connection_id = v_pc_id;
		ELSIF v_pc.rpc_device_id = in_dev2_id AND v_pc.rpc_power_interface_port = in_port2_id THEN
			update	device_power_connection
			   set	device_id = in_dev1_id,
					power_interface_port = in_port1_id
			  where	device_power_connection_id = v_pc_id;
		END IF;
		return 1;
	END;

	-------------------------------------------------------------------
	-- setup console information (dns and whatnot)
	-------------------------------------------------------------------
	PROCEDURE setup_conscfg_record (
		in_physportid   physical_port.physical_port_id%type,
		in_name	 	device.device_name%type,
		in_dstsvr       device.device_name%type
	) IS
		v_zoneid	dns_domain.dns_domain_id%type;
		v_recid		dns_record.dns_record_id%type;
		v_val		dns_record.dns_value%type;
		v_isthere	boolean;
		v_dstsvr	varchar2(1024);
	BEGIN
		select	dns_domain_id
		  into	v_zoneid
		  from	dns_domain
		 where	soa_name = GC_conscfg_zone;

		-- to ensure cname is properly terminated
		v_val := substr(in_dstsvr, -1, 1);
		IF ( v_val != '.' )  THEN
			v_dstsvr := in_dstsvr || '.';
		ELSE
			v_dstsvr := in_dstsvr;
		END IF;

		v_isthere := true;
		BEGIN
			select	dns_record_id, dns_value
			  into	v_recid, v_val
			  from	dns_record
			 where	dns_domain_id = v_zoneid
			  and	dns_name = in_name;
		EXCEPTION WHEN no_data_found THEN
			v_isthere := false;
		END;

		if (v_isthere = true) THEN
			if( v_val != v_dstsvr) THEN
				update 	dns_record
				  set	dns_value = v_dstsvr
				 where	dns_record_id = v_recid;
			END IF;
		ELSE
			insert into dns_record (
				dns_name, dns_domain_id, dns_class, dns_type,
				dns_value
			) values (
				in_name, v_zoneid, 'IN', 'CNAME',
				v_dstsvr
			);
		END IF;

	END;

	-------------------------------------------------------------------
	-- cleanup a console connection
	-------------------------------------------------------------------
	PROCEDURE delete_conscfg_record (
		in_name	 	device.device_name%type
	) IS
		v_zoneid	dns_domain.dns_domain_id%type;
	BEGIN
		select	dns_domain_id
		  into	v_zoneid
		  from	dns_domain
		 where	soa_name = GC_conscfg_zone;

		delete from dns_record
		 where	dns_name = in_name
		   and	dns_domain_id = v_zoneid;
	END;

end;
/
show errors;
