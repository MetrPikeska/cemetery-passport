-- Enable PostGIS (if not already enabled)
CREATE EXTENSION IF NOT EXISTS postgis;

-- Drop all existing tables (CASCADE will drop dependent tables as well)
DROP TABLE IF EXISTS photos CASCADE;
DROP TABLE IF EXISTS deceased CASCADE;
DROP TABLE IF EXISTS graves CASCADE;
-- Also drop tables from the previous complex schema if they were created and not explicitly dropped by `new_init.sql`
DROP TABLE IF EXISTS change_log CASCADE;
DROP TABLE IF EXISTS vegetation_inventory CASCADE;
DROP TABLE IF EXISTS cemetery_infrastructure CASCADE;
DROP TABLE IF EXISTS cadastral_parcels CASCADE;
DROP TABLE IF EXISTS inspection_logs CASCADE;
DROP TABLE IF EXISTS maintenance_records CASCADE;
DROP TABLE IF EXISTS contract_history CASCADE;
DROP TABLE IF EXISTS lease_contracts CASCADE;
DROP TABLE IF EXISTS leaseholders CASCADE;
DROP TABLE IF EXISTS interments CASCADE;
DROP TABLE IF EXISTS persons CASCADE;
DROP TABLE IF EXISTS ref_inspection_types CASCADE;
DROP TABLE IF EXISTS ref_maintenance_types CASCADE;
DROP TABLE IF EXISTS ref_leaseholder_types CASCADE;
DROP TABLE IF EXISTS ref_cemetery_sections CASCADE;
DROP TABLE IF EXISTS ref_grave_conditions CASCADE;
DROP TABLE IF EXISTS ref_grave_types CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- TABLE: graves (simplified to 6 attributes + id)
CREATE TABLE graves (
    id SERIAL PRIMARY KEY,
    section TEXT NOT NULL,
    grave_number TEXT NOT NULL,
    type TEXT,
    condition TEXT,
    geom geometry(POLYGON, 4326)
);

-- Index for spatial queries
CREATE INDEX graves_geom_idx ON graves USING GIST (geom);
CREATE UNIQUE INDEX graves_section_number_idx ON graves (section, grave_number);

-- TABLE: deceased
CREATE TABLE deceased (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    birth_year INT,
    death_year INT,
    grave_id INT REFERENCES graves(id) ON DELETE CASCADE
);
CREATE INDEX deceased_grave_id_idx ON deceased (grave_id);


-- TABLE: photos
CREATE TABLE photos (
    id SERIAL PRIMARY KEY,
    grave_id INT REFERENCES graves(id) ON DELETE CASCADE,
    url TEXT NOT NULL
);
CREATE INDEX photos_grave_id_idx ON photos (grave_id);


-- DUMMY DATA

-- Central coordinates for the cemetery area (using the user's provided home point)
-- Note: ST_GeomFromText expects Longitude Latitude for WGS84 (4326)
DO $$
DECLARE
    center_lon DOUBLE PRECISION := 18.20934;
    center_lat DOUBLE PRECISION := 49.88231;
    i INT;
    current_grave_id INT;
BEGIN
    -- Graves (50 graves)
    FOR i IN 1..50 LOOP
        INSERT INTO graves (section, grave_number, type, condition, geom) VALUES
        (
            'Sec' || ( (i - 1) / 10 + 1 )::TEXT, -- Sections 1-5
            LPAD( ( (i - 1) % 10 + 1 )::TEXT, 2, '0'), -- Grave numbers 01-10 per section
            CASE (i % 3)
                WHEN 0 THEN 'Burial'
                WHEN 1 THEN 'Cremation'
                ELSE 'Family Plot'
            END,
            CASE (i % 4)
                WHEN 0 THEN 'Good'
                WHEN 1 THEN 'Fair'
                WHEN 2 THEN 'Poor'
                ELSE 'Excellent'
            END,
            ST_GeomFromText(
                'POLYGON((' ||
                (center_lon + (i * 0.00005)) || ' ' || (center_lat + (i * 0.00005)) || ', ' ||
                (center_lon + (i * 0.00005)) || ' ' || (center_lat + (i * 0.00005) + 0.00003) || ', ' ||
                (center_lon + (i * 0.00005) + 0.00003) || ' ' || (center_lat + (i * 0.00005) + 0.00003) || ', ' ||
                (center_lon + (i * 0.00005) + 0.00003) || ' ' || (center_lat + (i * 0.00005)) || ', ' ||
                (center_lon + (i * 0.00005)) || ' ' || (center_lat + (i * 0.00005)) ||
                '))', 4326
            )
        )
        RETURNING id INTO current_grave_id;

        -- Deceased (1-3 deceased per grave, total 80+)
        INSERT INTO deceased (name, birth_year, death_year, grave_id) VALUES
        ('Person ' || (i * 2 - 1)::TEXT, 1900 + (i * 2) % 100, 1980 + (i * 3) % 40, current_grave_id);
        IF random() > 0.3 THEN -- 70% chance for a second deceased
            INSERT INTO deceased (name, birth_year, death_year, grave_id) VALUES
            ('Person ' || (i * 2)::TEXT, 1920 + (i * 4) % 90, 2000 + (i * 2) % 20, current_grave_id);
        END IF;
        IF random() > 0.7 THEN -- 30% chance for a third deceased
            INSERT INTO deceased (name, birth_year, death_year, grave_id) VALUES
            ('Person ' || (i * 2 + 1)::TEXT, 1940 + (i * 3) % 80, 2010 + (i * 1) % 10, current_grave_id);
        END IF;

        -- Photos (1-2 photos per grave)
        INSERT INTO photos (grave_id, url) VALUES
        (current_grave_id, 'https://via.placeholder.com/150/' || LPAD((i * 10)::TEXT, 3, '0') || '/FFFFFF?text=Grave+' || current_grave_id);
        IF random() > 0.5 THEN -- 50% chance for a second photo
            INSERT INTO photos (grave_id, url) VALUES
            (current_grave_id, 'https://via.placeholder.com/150/' || LPAD((i * 10 + 50)::TEXT, 3, '0') || '/000000?text=Detail+' || current_grave_id);
        END IF;
    END LOOP;
END $$;
