local core = require "silly.core"
local rpc = require "rpc"
local zproto = require "zproto"
local crypt = require "crypt"

local logic = zproto:parse [[
test 0xff {
        .name:string 1
        .age:integer 2
        .rand:string 3
}
]]

local function request(fd, index)
        return function()
                local test = {
                        name = "hello",
                        age = index,
                        rand = crypt.randomkey(),
                }
                local res = rpc.call(fd, "test", test)
                if not res then
                        print("rpc call fail", res)
                        return
                end
                assert(test.rand == res.rand)
                print("rpc call", index, "ret:", res.name, res.age)
        end
end

core.start(function()
        print("connect 8989 start")
        local fd = rpc.connect {
                addr = "127.0.0.1@9999",
                proto = logic,
                pack = function(data)
                        return crypt.aesencode("hello", data)
                end,
                unpack = function(data, sz)
                        return crypt.aesdecode("hello", data, sz)
                end,
                close = function(fd, errno)
                        print("close", fd, errno)
                end,
        }

        for i = 1, 5 do
                core.fork(request(fd, i))
        end
        core.sleep(10000)
        rpc.close(fd)
        core.quit()
end)


