-- Working DX Cluster list for cqrlog-xd
-- Tested and verified March 2026
-- Insert into cqrlog_common.dxclusters

DELETE FROM dxclusters;

INSERT INTO dxclusters (description, address, port) VALUES
('HamQTH', 'hamqth.com', 7300),
('WA9PIE (Chicago, USA)', 'hrd.wa9pie.net', 8000),
('W3LPL (USA East)', 'w3lpl.net', 7373),
('EA4RCH (Spain)', 'ea4rch.ure.es', 7300),
('W9PA (USA Midwest)', 'dxc.w9pa.net', 7373),
('WB3FFV (Maryland, USA)', 'dxc.wb3ffv.us', 7300),
('K1TTT (New England, USA)', 'k1ttt.net', 7373),
('W1NR (New England, USA)', 'dx.w1nr.net', 7300),
('K4ZR (Alabama, USA)', 'k4zr.no-ip.org', 7300),
('dxspider.co.uk (UK)', 'dxspider.co.uk', 7300);
