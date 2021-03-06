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
--
-- $Id$

-- drop materialized view mv_uclass_user_expanded;

create materialized view mv_uclass_user_expanded
build immediate
refresh complete
start with sysdate
next sysdate + 1/96
with primary key
	AS (
	SELECT dum.uclass_id, dm.system_user_id FROM (
		SELECT DISTINCT dhe.child_dept_id AS dept_id, uhe.uclass_id FROM (
			SELECT uclass_id, child_uclass_id FROM (
			SELECT uclass_id, uclass_id AS child_uclass_id FROM uclass
				UNION
				SELECT connect_by_root uclass_id AS uclass_id, child_uclass_id
				FROM  uclass_hier
				CONNECT BY PRIOR child_uclass_id = uclass_id
			)
		) uhe
		INNER JOIN uclass_dept ud ON ud.uclass_id = uhe.child_uclass_id
		INNER JOIN (
			SELECT dept_id AS dept_id, dept_id AS child_dept_id FROM dept
			UNION
			SELECT connect_by_root parent_dept_id AS dept_id,
					dept_id AS child_dept_id
			FROM  (SELECT * FROM dept WHERE parent_dept_id IS NOT NULL)
			CONNECT BY PRIOR dept_id = parent_dept_id
		) dhe
		ON ud.dept_id = dhe.dept_id OR ud.dept_id = dhe.dept_id
		INNER JOIN uclass ON uclass.uclass_id = uhe.child_uclass_id
	) dum
	INNER JOIN dept_member dm
	ON (
		dum.dept_id = dm.dept_id
		AND (dm.finish_date IS NULL OR dm.finish_date >= sysdate)
		AND  (dm.start_date IS NULL OR dm.start_date <= sysdate)
	)
	UNION
	SELECT uch.uclass_id, uu.system_user_id FROM (
		SELECT connect_by_root uclass_id AS uclass_id, child_uclass_id
		FROM uclass_hier CONNECT BY PRIOR child_uclass_id = uclass_id
	) uch
	INNER JOIN uclass_user uu ON uch.child_uclass_id = uu.uclass_id
	UNION
	SELECT uu.uclass_id, uu.system_user_id FROM uclass_user uu
);

CREATE INDEX IDX_MV_UC_Usr_Exp_SysUID ON MV_UClass_User_Expanded (
	System_User_ID
) TABLESPACE INDEX01;

CREATE INDEX IDX_MV_UC_Usr_Exp_UCID ON MV_UClass_User_Expanded (
	UClass_ID
) TABLESPACE INDEX01;

CREATE INDEX IDX_MV_UC_Usr_Exp_SUID_UCID ON MV_UClass_User_Expanded (
	System_User_ID,
	UClass_ID
) TABLESPACE INDEX01;

--  EXECUTE DBMS_MVIEW.REFRESH('mv_uclass_user_expanded_detail');
