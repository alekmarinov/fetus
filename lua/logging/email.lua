-------------------------------------------------------------------------------
-- $Id: email.lua,v 1.2.1.1 2006/01/07 14:26:20 alek Exp $
--
-- Emails logging information to the given recipient
--
-- Authors:
--   Thiago Costa Ponte (thiago@ideais.com.br)
--
-- Copyright (c) 2004 Kepler Project
-------------------------------------------------------------------------------

require ("logging")
local smtp = require ("socket.smtp")

function logging.email(params)
    params = params or {}
    params.headers = params.headers or {}
    
    if params.from == nil then
        return nil, "'from' parameter is required"
    end

    if params.rcpt == nil then
        return nil, "'rcpt' parameter is required"
    end

    return logging.new( function(self, level, message)
                            local s = logging.prepareLogMsg(params.logPattern, os.date(), level, message)
                            if params.headers.subject then
                                params.headers.subject = logging.prepareLogMsg(params.headers.subject, os.date(), level, message)
                            end
                            local msg = { from = params.from, headers = params.headers, body = s }
                            params.source = smtp.message(msg)

                            local r, e = smtp.send(params)
                            if not r then
                                return nil, e
                            end
                            return true
                        end
                      )
end
