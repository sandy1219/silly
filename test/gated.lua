local core = require "silly.core"
local gate = require "gate"
local crypt = require "crypt"
local np = require "netpacket"

gate.listen {
        addr= "@9999",
        pack = function(data)
                return crypt.aesencode("hello", data)
        end,
        unpack = function(data, sz)
                local data, sz = crypt.aesdecode("hello", data, sz)
                return core.tostring(data, sz)
        end,
        accept = function(fd, addr)
                print("accept", fd, addr)
        end,

        close = function(fd, errno)
                print("closed", fd, errno)
                core.sleep(5000)
                core.quit()
        end,

        data = function(fd, msg)
                print("recv data", fd, msg)
                gate.send(fd, msg)
                core.sleep(1000)
                gate.send(fd, msg .. "t\n")
                print("port1 data finish")
        end,
}

gate.listen {
        addr = "@9998",
        accept = function(fd, addr)
                print("accept", fd, addr)
        end,

        close = function(fd, errno)
                print("close", fd, errno)
        end,
        data = function(fd, msg)
                print("data", fd, msg)
                gate.send(fd, msg)
                core.sleep(100)
                print("port2 data finish")
        end,
}

