-- Modem network lib, trying to be most compatible with legacy app using direct "modem" network and
-- the new socket object aspect used by network library
local protocol = {}
local event = require("event")
local listenedPorts = {}
local component = ...
local modem = component.modem

function protocol.isProtocolAddress(addr)
	return addr:len() == 36 -- todo: more checks
end

function protocol.cancelAsync(id)
	event.cancel(id)
end

function protocol.getOSILayer()
	return 2
end

function protocol.listenAsync(port, callback)
	local f = nil
	modem.open(port)
	f = function(_,_,sender,p,data)
		if p == port then
			local sock = protocol.open(sender, p)
			sock.rbuf = data
			callback(sock)
			event.ignore("modem_message", f)
		end
	end
	return event.listen("modem_message", f)
end

function protocol.listen(port)
	local sock = {}
	modem.open(port)
	while true do
		local sig = table.pack(event.pull("modem_message"))
		local name, sender, p = sig[1], sig[3], sig[4]
		if p == port then
			sock = protocol.open(sender, p)
			sock.rbuf = sig[5]
			break
		end
	end
	return sock
end

function protocol.getAddress() -- the public address
	return modem.address
end

function protocol.setComponentAddress(address)
	if component.type(address) ~= "modem" then
		error("invalid component")
	end
	modem = component.proxy(address)
end

function protocol.getComponentAddress()
	return modem.address
end

function protocol.getAddresses() -- public addresses
	return {protocol.getAddress()}
end

function protocol.open(addr, dport)
	modem.open(dport)
	return {
		rbuf = nil,
		dest = addr,
		port = dport,
		close = function(self)
			modem.close(self.port)
		end,
		write = function(self, ...)
			if dest == "ffffffff-ffff-ffff-ffff-ffffffffffff" then  -- broadcast address
				modem.broadcast(self.port, ...)
			else
				modem.send(self.dest, self.port, ...)
			end
		end,
		read = function(self)
			if self.rbuf ~= nil then
				local r = self.rbuf
				self.rbuf = nil
				return r
			end
			while true do
				local sig = table.pack(event.pull())
				if sig[1] == "modem_message" and sig[3] == self.dest and sig[4] == self.port then -- if is from destination/receiver and same port
					return sig[5]
				end
			end
		end
	}
end

return "modem", protocol