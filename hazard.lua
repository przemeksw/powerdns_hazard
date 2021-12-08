hazard=newDS()
for line in io.lines("/etc/powerdns/hazard.dane") do
    hazard:add{line};
end

excluded_hosts = newNMG()
excluded_hosts:addMask("46.45.86.251")
excluded_hosts:addMask("46.45.114.0/25")
excluded_hosts:addMask("46.45.87.0/25")
excluded_hosts:addMask("46.45.78.10")

function preresolve(dq)
    if hazard:check(dq.qname) then
    dq.appliedPolicy.policyKind = pdns.policykinds.NODATA
    print("bb");
        if dq.qtype == pdns.A then
            dq:addAnswer(pdns.A,"145.237.235.240")
            print("aa");
            return true;
        end
    end
    return false;
end

--function nxdomain(dq)
--    if dq.qtype == pdns.A and not excluded_hosts:match(dq.remoteaddr) then
--        pdnslog("NXDOMAIN from:" .. dq.remoteaddr:toString() .. " for: " .. dq.qname:toString())
--    end
--    return false
--end
