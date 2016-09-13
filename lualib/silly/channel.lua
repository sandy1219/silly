local core = require "silly.core"

local channel = {}

local mt = {__index = channel}

local function start(self, func)
        core.fork(function()
                while true do
                        if #self.queue == 0 then
                                self.co = core.running()
                                local ok, err = core.pcall(func, core.wait())
                                assert(not self.co)
                                if not ok then
                                        print("channel", err)
                                end
                        end
                        while #self.queue > 0 do
                                local t = table.remove(self.queue, 1)
                                local ok, err = core.pcall(func, table.unpack(t))
                                if not ok then
                                        print("channel", err)
                                end
                        end
                end

        end)
end


function channel.run(func)
        local self = {}
        self.queue = {}
        self.co = false
        setmetatable(self, mt)
        start(self, func)
        return self
end

function channel.push(self, ...)
        if self.co then
                local co = self.co
                self.co = false
                core.wakeup(co, ...)
        else
                table.insert(self.queue, {...})
        end
end


return channel

