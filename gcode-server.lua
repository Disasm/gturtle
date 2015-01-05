local args = {...}

local scriptPasteId = "mXrtbiq7"

function usage()
    print("Usage: gcode-server {params}")
    print("    shell <channel>")
    print("    file <channel> <path>")
    print("    pastebin <channel> <paste_id>")
    print("    update")
end

if #args < 1 then
    usage()
    return
end

local cmd = args[1]
local channel = nil
local pasteId = nil
local filePath = nil

if cmd == "shell" then
    if #args < 2 then
        usage()
        return
    end
    channel = tonumber(args[2])
elseif cmd == "file" then
    if #args < 3 then
        usage()
        return
    end
    channel = tonumber(args[2])
    filePath = args[3]
elseif cmd == "pastebin" then
    if #args < 3 then
        usage()
        return
    end
    channel = tonumber(args[2])
    pasteId = args[3]
elseif cmd == "update" then
    print("Updating...")
    shell.run("rm", "server")
    shell.run("pastebin", "get "..scriptPasteId.." server")
    return
end

local modem = nil
for t=1,5 do
    Sides = peripheral.getNames()
    for i = 1,#Sides do
        if peripheral.getType(Sides[i]) == "modem" then
            modem = peripheral.wrap(Sides[i])
            break
        end
    end
    if modem ~= nil then
        break
    else
        sleep(0.5)
    end
end

if modem == nil then
    print("Can't find modem. Press any key to shutdown.")
    os.pullEvent("key")
    os.shutdown()
end

local serverChannel = math.random(1,65535)
print("ServerChannel: "..serverChannel..", ClientChannel: "..channel)

modem.open(serverChannel)
print("Listening channel "..serverChannel)

local terminate = false

function readFunction()
    local s = read()
    if s == "q" or s == "quit" then
        terminate = true
        return
    end
    modem.transmit(channel, serverChannel, string.upper(s))
end

function recvFunction()
    local event, p1, p2, p3, message = os.pullEvent("modem_message")
    if event == "modem_message" then
        print(message)
    end
end

if cmd == "shell" then
    while not terminate do
        parallel.waitForAny(readFunction, recvFunction)
    end
end
