UPDATE projects SET strategy_id = 'Pipeline I'
    WHERE projects.id IN (
        SELECT DISTINCT(p.id) FROM projects p JOIN project_sponsors ps ON p.id = ps.project_id
        WHERE ps.sponsor_id <> 'Decipher'
    );

UPDATE projects SET strategy_id = 'Pipeline II'
    WHERE projects.id IN (
        SELECT DISTINCT(p.id) FROM projects p JOIN project_sponsors ps ON p.id = ps.project_id
        WHERE ps.sponsor_id = 'Decipher'
    );

INSERT INTO schema_versions(version) VALUES (132);
