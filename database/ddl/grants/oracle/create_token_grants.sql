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
--
-- $Id$
--
CREATE ROLE TOKEN_MGMT_ROLE;
GRANT EXECUTE ON JazzHands.Token_Util TO TOKEN_MGMT_ROLE;
GRANT EXECUTE ON JazzHands.Time_Util TO TOKEN_MGMT_ROLE;
GRANT SELECT ON JazzHands.V_Token TO TOKEN_MGMT_ROLE;
GRANT SELECT ON JazzHands.Token TO TOKEN_MGMT_ROLE;
GRANT SELECT ON JazzHands.Token_Sequence TO TOKEN_MGMT_ROLE;
GRANT SELECT ON JazzHands.System_User_Token TO TOKEN_MGMT_ROLE;
GRANT SELECT ON JazzHands.System_User TO TOKEN_MGMT_ROLE;
GRANT SELECT ON JazzHands.User_Unix_Info TO TOKEN_MGMT_ROLE;
GRANT CREATE SESSION TO TOKEN_MGMT_ROLE;

CREATE ROLE TOKEN_SYNC_ROLE;
GRANT EXECUTE ON JazzHands.Token_Util TO TOKEN_SYNC_ROLE;
GRANT EXECUTE ON JazzHands.Time_Util TO TOKEN_SYNC_ROLE;
GRANT SELECT, UPDATE ON JazzHands.Token TO TOKEN_SYNC_ROLE;
GRANT SELECT, UPDATE ON JazzHands.Token_Sequence TO TOKEN_SYNC_ROLE;
GRANT SELECT, UPDATE ON JazzHands.System_User_Token TO TOKEN_SYNC_ROLE;
GRANT SELECT ON JazzHands.V_Token TO TOKEN_SYNC_ROLE;
GRANT SELECT ON JazzHands.System_User TO TOKEN_SYNC_ROLE;
GRANT CREATE SESSION TO TOKEN_SYNC_ROLE;

CREATE ROLE TOKEN_LOAD_ROLE;
GRANT SELECT ON JazzHands.V_Token TO TOKEN_LOAD_ROLE;
GRANT SELECT, INSERT, UPDATE ON JazzHands.Token TO TOKEN_LOAD_ROLE;
GRANT SELECT, INSERT, UPDATE ON JazzHands.Token_Sequence TO TOKEN_LOAD_ROLE;
GRANT CREATE SESSION TO TOKEN_LOAD_ROLE;

GRANT Token_Mgmt_Role to JazzHandsTools;
CREATE OR REPLACE SYNONYM JazzHandstools.Token_Util FOR JazzHands.Token_Util;
CREATE OR REPLACE SYNONYM JazzHandstools.Time_Util FOR JazzHands.Time_Util;
CREATE OR REPLACE SYNONYM JazzHandstools.Token FOR JazzHands.Token;
CREATE OR REPLACE SYNONYM JazzHandstools.System_User_Token FOR JazzHands.System_User_Token;
CREATE OR REPLACE SYNONYM JazzHandstools.V_Token FOR JazzHands.V_Token;

GRANT Token_Mgmt_Role to AP_TokenMgmt;
CREATE OR REPLACE SYNONYM AP_TokenMgmt.Token_Util FOR JazzHands.Token_Util;
CREATE OR REPLACE SYNONYM AP_TokenMgmt.Time_Util FOR JazzHands.Time_Util;
CREATE OR REPLACE SYNONYM AP_TokenMgmt.Token FOR JazzHands.Token;
CREATE OR REPLACE SYNONYM AP_TokenMgmt.System_User_Token FOR JazzHands.System_User_Token;
CREATE OR REPLACE SYNONYM AP_TokenMgmt.V_Token FOR JazzHands.V_Token;
CREATE OR REPLACE SYNONYM AP_TokenMgmt.System_User FOR JazzHands.System_User;
CREATE OR REPLACE SYNONYM AP_TokenMgmt.User_Unix_Info FOR JazzHands.User_Unix_Info;
CREATE OR REPLACE SYNONYM AP_TokenMgmt.Token_Sequence FOR JazzHands.Token_Sequence;

GRANT Token_Sync_Role to AP_TokenSync;
CREATE OR REPLACE SYNONYM AP_TOKENSYNC.V_Token FOR JazzHands.V_Token;
CREATE OR REPLACE SYNONYM AP_TOKENSYNC.Token FOR JazzHands.Token;
CREATE OR REPLACE SYNONYM AP_TOKENSYNC.Token_Sequence FOR JazzHands.Token_Sequence;
CREATE OR REPLACE SYNONYM AP_TOKENSYNC.System_User_Token FOR JazzHands.System_User_Token;
CREATE OR REPLACE SYNONYM AP_TOKENSYNC.System_User FOR JazzHands.System_User;
CREATE OR REPLACE SYNONYM AP_TOKENSYNC.Token_Util FOR JazzHands.Token_Util;
CREATE OR REPLACE SYNONYM AP_TOKENSYNC.Time_Util FOR JazzHands.Time_Util;

GRANT Token_Load_Role to AP_TokenLoad;
CREATE OR REPLACE SYNONYM AP_TOKENLOAD.V_Token FOR JazzHands.V_Token;
CREATE OR REPLACE SYNONYM AP_TOKENLOAD.Token FOR JazzHands.Token;
CREATE OR REPLACE SYNONYM AP_TOKENLOAD.Token_Sequence FOR JazzHands.Token_Sequence;

