-- Enable PostGIS (if not already enabled)
CREATE EXTENSION IF NOT EXISTS postgis;

-- Drop all existing tables (CASCADE will drop dependent tables as well)
DROP TABLE IF EXISTS photos CASCADE;
DROP TABLE IF EXISTS deceased CASCADE;
DROP TABLE IF EXISTS graves CASCADE;

-- Drop new tables if they exist for clean re-creation during migration
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
DROP TABLE IF EXISTS users CASCADE; -- If you decide to include a users table

-- =======================================================
-- Reference Tables
-- =======================================================

CREATE TABLE ref_grave_types (
    type_id SERIAL PRIMARY KEY,
    type_name TEXT UNIQUE NOT NULL,
    description TEXT,
    date_created TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT NOT NULL DEFAULT 'system',
    date_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT NOT NULL DEFAULT 'system',
    notes TEXT
);
CREATE INDEX idx_ref_grave_types_name ON ref_grave_types (type_name);

CREATE TABLE ref_grave_conditions (
    condition_id SERIAL PRIMARY KEY,
    condition_name TEXT UNIQUE NOT NULL,
    description TEXT,
    date_created TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT NOT NULL DEFAULT 'system',
    date_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT NOT NULL DEFAULT 'system',
    notes TEXT
);
CREATE INDEX idx_ref_grave_conditions_name ON ref_grave_conditions (condition_name);

CREATE TABLE ref_cemetery_sections (
    section_id SERIAL PRIMARY KEY,
    section_name TEXT UNIQUE NOT NULL,
    description TEXT,
    geom geometry(POLYGON, 4326),
    date_created TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT NOT NULL DEFAULT 'system',
    date_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT NOT NULL DEFAULT 'system',
    notes TEXT
);
CREATE INDEX idx_ref_cemetery_sections_name ON ref_cemetery_sections (section_name);
CREATE INDEX idx_ref_cemetery_sections_geom ON ref_cemetery_sections USING GIST (geom);

CREATE TABLE ref_leaseholder_types (
    leaseholder_type_id SERIAL PRIMARY KEY,
    type_name TEXT UNIQUE NOT NULL,
    description TEXT,
    date_created TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT NOT NULL DEFAULT 'system',
    date_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT NOT NULL DEFAULT 'system',
    notes TEXT
);
CREATE INDEX idx_ref_leaseholder_types_name ON ref_leaseholder_types (type_name);

CREATE TABLE ref_maintenance_types (
    maintenance_type_id SERIAL PRIMARY KEY,
    type_name TEXT UNIQUE NOT NULL,
    description TEXT,
    date_created TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT NOT NULL DEFAULT 'system',
    date_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT NOT NULL DEFAULT 'system',
    notes TEXT
);
CREATE INDEX idx_ref_maintenance_types_name ON ref_maintenance_types (type_name);

CREATE TABLE ref_inspection_types (
    inspection_type_id SERIAL PRIMARY KEY,
    type_name TEXT UNIQUE NOT NULL,
    description TEXT,
    date_created TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT NOT NULL DEFAULT 'system',
    date_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT NOT NULL DEFAULT 'system',
    notes TEXT
);
CREATE INDEX idx_ref_inspection_types_name ON ref_inspection_types (type_name);

-- =======================================================
-- Core Tables
-- =======================================================

CREATE TABLE cadastral_parcels (
    parcel_id SERIAL PRIMARY KEY,
    parcel_number TEXT UNIQUE NOT NULL,
    owner TEXT, -- Could be FK to persons or organizations if needed
    area_sqm NUMERIC(12,2),
    notes TEXT,
    geom geometry(POLYGON, 4326) NOT NULL,
    date_created TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT NOT NULL DEFAULT 'system',
    date_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT NOT NULL DEFAULT 'system'
);
CREATE INDEX idx_cadastral_parcels_geom ON cadastral_parcels USING GIST (geom);
CREATE INDEX idx_cadastral_parcels_number ON cadastral_parcels (parcel_number);

CREATE TABLE graves (
    grave_id SERIAL PRIMARY KEY,
    grave_number TEXT NOT NULL,
    section_id INT NOT NULL REFERENCES ref_cemetery_sections(section_id) ON DELETE RESTRICT,
    grave_type_id INT NOT NULL REFERENCES ref_grave_types(type_id) ON DELETE RESTRICT,
    grave_condition_id INT NOT NULL REFERENCES ref_grave_conditions(condition_id) ON DELETE RESTRICT,
    cadastral_parcel_id INT REFERENCES cadastral_parcels(parcel_id) ON DELETE SET NULL,
    notes TEXT,
    geom geometry(POLYGON, 4326) NOT NULL,
    date_created TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT NOT NULL DEFAULT 'system',
    date_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT NOT NULL DEFAULT 'system',
    UNIQUE (section_id, grave_number) -- Ensure unique grave number within a section
);
CREATE INDEX graves_geom_idx ON graves USING GIST (geom);
CREATE INDEX idx_graves_section_id ON graves (section_id);
CREATE INDEX idx_graves_grave_number ON graves (grave_number);


CREATE TABLE persons (
    person_id SERIAL PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    birth_date DATE,
    death_date DATE,
    place_of_birth TEXT,
    place_of_death TEXT,
    notes TEXT,
    date_created TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT NOT NULL DEFAULT 'system',
    date_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT NOT NULL DEFAULT 'system'
);
CREATE INDEX idx_persons_last_name ON persons (last_name);
CREATE INDEX idx_persons_first_name ON persons (first_name);

CREATE TABLE interments (
    interment_id SERIAL PRIMARY KEY,
    grave_id INT NOT NULL REFERENCES graves(grave_id) ON DELETE CASCADE,
    person_id INT NOT NULL REFERENCES persons(person_id) ON DELETE RESTRICT,
    date_of_interment DATE,
    notes TEXT,
    date_created TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT NOT NULL DEFAULT 'system',
    date_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT NOT NULL DEFAULT 'system',
    UNIQUE (grave_id, person_id) -- A person can be interred in a grave only once
);
CREATE INDEX idx_interments_grave_id ON interments (grave_id);
CREATE INDEX idx_interments_person_id ON interments (person_id);

CREATE TABLE photos (
    photo_id SERIAL PRIMARY KEY,
    grave_id INT REFERENCES graves(grave_id) ON DELETE CASCADE,
    person_id INT REFERENCES persons(person_id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    description TEXT,
    photo_date DATE,
    taken_by TEXT, -- Could be FK to users
    date_created TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT NOT NULL DEFAULT 'system',
    date_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT NOT NULL DEFAULT 'system',
    CONSTRAINT chk_photo_assignment CHECK (grave_id IS NOT NULL OR person_id IS NOT NULL)
);
CREATE INDEX idx_photos_grave_id ON photos (grave_id);
CREATE INDEX idx_photos_person_id ON photos (person_id);

-- =======================================================
-- Leaseholder & Contract Management
-- =======================================================

CREATE TABLE leaseholders (
    leaseholder_id SERIAL PRIMARY KEY,
    person_id INT REFERENCES persons(person_id) ON DELETE SET NULL, -- If an individual
    organization_name TEXT, -- If an organization
    leaseholder_type_id INT NOT NULL REFERENCES ref_leaseholder_types(leaseholder_type_id) ON DELETE RESTRICT,
    contact_email TEXT,
    contact_phone TEXT,
    address TEXT,
    notes TEXT,
    date_created TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT NOT NULL DEFAULT 'system',
    date_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT NOT NULL DEFAULT 'system',
    CONSTRAINT chk_leaseholder_type CHECK (
        (person_id IS NOT NULL AND organization_name IS NULL) OR
        (person_id IS NULL AND organization_name IS NOT NULL)
    )
);
CREATE INDEX idx_leaseholders_person_id ON leaseholders (person_id);
CREATE INDEX idx_leaseholders_organization_name ON leaseholders (organization_name);

CREATE TABLE lease_contracts (
    contract_id SERIAL PRIMARY KEY,
    grave_id INT NOT NULL REFERENCES graves(grave_id) ON DELETE RESTRICT,
    leaseholder_id INT NOT NULL REFERENCES leaseholders(leaseholder_id) ON DELETE RESTRICT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    contract_terms TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    renewal_date DATE,
    notes TEXT,
    date_created TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT NOT NULL DEFAULT 'system',
    date_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT NOT NULL DEFAULT 'system',
    UNIQUE (grave_id, leaseholder_id, start_date), -- Ensure a unique contract for a grave/leaseholder/start date
    CONSTRAINT chk_dates CHECK (end_date >= start_date)
);
CREATE INDEX idx_lease_contracts_grave_id ON lease_contracts (grave_id);
CREATE INDEX idx_lease_contracts_leaseholder_id ON lease_contracts (leaseholder_id);
CREATE INDEX idx_lease_contracts_end_date ON lease_contracts (end_date); -- Useful for finding expired contracts

CREATE TABLE contract_history (
    history_id SERIAL PRIMARY KEY,
    contract_id INT NOT NULL REFERENCES lease_contracts(contract_id) ON DELETE CASCADE,
    change_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    changed_by TEXT NOT NULL DEFAULT 'system', -- Could be FK to users
    change_type TEXT NOT NULL, -- e.g., 'CREATED', 'RENEWED', 'TERMINATED', 'UPDATED'
    old_values JSONB,
    new_values JSONB,
    notes TEXT,
    date_created TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT NOT NULL DEFAULT 'system',
    date_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT NOT NULL DEFAULT 'system'
);
CREATE INDEX idx_contract_history_contract_id ON contract_history (contract_id);
CREATE INDEX idx_contract_history_change_date ON contract_history (change_date);

-- =======================================================
-- Maintenance & Inspections
-- =======================================================

CREATE TABLE maintenance_records (
    maintenance_id SERIAL PRIMARY KEY,
    grave_id INT NOT NULL REFERENCES graves(grave_id) ON DELETE CASCADE,
    maintenance_type_id INT NOT NULL REFERENCES ref_maintenance_types(maintenance_type_id) ON DELETE RESTRICT,
    maintenance_date DATE NOT NULL,
    description TEXT,
    performed_by TEXT, -- Could be FK to users
    cost NUMERIC(10,2),
    notes TEXT,
    date_created TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT NOT NULL DEFAULT 'system',
    date_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT NOT NULL DEFAULT 'system'
);
CREATE INDEX idx_maintenance_records_grave_id ON maintenance_records (grave_id);
CREATE INDEX idx_maintenance_records_date ON maintenance_records (maintenance_date);

CREATE TABLE inspection_logs (
    inspection_id SERIAL PRIMARY KEY,
    grave_id INT NOT NULL REFERENCES graves(grave_id) ON DELETE CASCADE,
    inspection_type_id INT NOT NULL REFERENCES ref_inspection_types(inspection_type_id) ON DELETE RESTRICT,
    inspection_date DATE NOT NULL,
    inspector TEXT, -- Could be FK to users
    condition_assessment TEXT,
    recommended_actions TEXT,
    next_inspection_date DATE,
    notes TEXT,
    date_created TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT NOT NULL DEFAULT 'system',
    date_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT NOT NULL DEFAULT 'system'
);
CREATE INDEX idx_inspection_logs_grave_id ON inspection_logs (grave_id);
CREATE INDEX idx_inspection_logs_date ON inspection_logs (inspection_date);

-- =======================================================
-- Cemetery Infrastructure & Vegetation
-- =======================================================

CREATE TABLE cemetery_infrastructure (
    infra_id SERIAL PRIMARY KEY,
    infra_name TEXT NOT NULL,
    infra_type TEXT NOT NULL, -- e.g., 'Path', 'Fence', 'Water Point', 'Building'
    description TEXT,
    notes TEXT,
    geom geometry(GEOMETRY, 4326) NOT NULL,
    date_created TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT NOT NULL DEFAULT 'system',
    date_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT NOT NULL DEFAULT 'system'
);
CREATE INDEX idx_cemetery_infrastructure_geom ON cemetery_infrastructure USING GIST (geom);
CREATE INDEX idx_cemetery_infrastructure_type ON cemetery_infrastructure (infra_type);

CREATE TABLE vegetation_inventory (
    vegetation_id SERIAL PRIMARY KEY,
    common_name TEXT NOT NULL,
    scientific_name TEXT,
    planting_date DATE,
    condition TEXT, -- e.g., 'Healthy', 'Needs pruning', 'Damaged'
    notes TEXT,
    geom geometry(POINT, 4326) NOT NULL,
    date_created TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT NOT NULL DEFAULT 'system',
    date_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT NOT NULL DEFAULT 'system'
);
CREATE INDEX idx_vegetation_inventory_geom ON vegetation_inventory USING GIST (geom);
CREATE INDEX idx_vegetation_inventory_common_name ON vegetation_inventory (common_name);

-- =======================================================
-- Auditing (Triggers would populate this table)
-- =======================================================

CREATE TABLE change_log (
    log_id SERIAL PRIMARY KEY,
    table_name TEXT NOT NULL,
    record_id INT NOT NULL,
    change_type TEXT NOT NULL, -- e.g., 'INSERT', 'UPDATE', 'DELETE'
    change_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    changed_by TEXT NOT NULL DEFAULT 'system', -- Could be FK to users
    old_data JSONB,
    new_data JSONB,
    notes TEXT,
    date_created TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT NOT NULL DEFAULT 'system',
    date_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT NOT NULL DEFAULT 'system'
);
CREATE INDEX idx_change_log_table_record ON change_log (table_name, record_id);
CREATE INDEX idx_change_log_change_date ON change_log (change_date);

-- =======================================================
-- Users (Optional - for created_by, updated_by, changed_by FKs)
-- =======================================================

/*
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'Viewer', -- e.g., 'Admin', 'Editor', 'Viewer'
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    date_created TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by TEXT NOT NULL DEFAULT 'system',
    date_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT NOT NULL DEFAULT 'system'
);
CREATE INDEX idx_users_username ON users (username);
*/

-- =======================================================
-- Dummy Data for Reference Tables
-- =======================================================

INSERT INTO ref_grave_types (type_name, description) VALUES
('Burial', 'Traditional ground burial plot.'),
('Cremation Niche', 'Space for cremated remains in a wall.'),
('Family Plot', 'Larger plot for multiple family members.'),
('Mausoleum', 'Above-ground structure for entombment.'),
('Columbarium', 'Structure with niches for urns.');

INSERT INTO ref_grave_conditions (condition_name, description) VALUES
('Excellent', 'Newly installed or perfectly maintained.'),
('Good', 'Well-maintained, minor wear.'),
('Fair', 'Noticeable wear, minor repairs needed.'),
('Poor', 'Significant damage, major repairs required.'),
('Dilapidated', 'Severely damaged, unstable, or overgrown.');

INSERT INTO ref_cemetery_sections (section_name, description, geom) VALUES
('Section A - Old Grove', 'Historic section with mature trees.', ST_GeomFromText('POLYGON((18.2085 49.8820, 18.2085 49.8825, 18.2090 49.8825, 18.2090 49.8820, 18.2085 49.8820))', 4326)),
('Section B - New Expansion', 'Recently opened area, modern design.', ST_GeomFromText('POLYGON((18.2090 49.8820, 18.2090 49.8825, 18.2095 49.8825, 18.2095 49.8820, 18.2090 49.8820))', 4326)),
('Section C - Lakeside View', 'Plots overlooking the cemetery pond.', ST_GeomFromText('POLYGON((18.2095 49.8820, 18.2095 49.8825, 18.2100 49.8825, 18.2100 49.8820, 18.2095 49.8820))', 4326));

INSERT INTO ref_leaseholder_types (type_name, description) VALUES
('Individual', 'A single person holding the lease.'),
('Family Representative', 'One family member holds the lease for a family plot.'),
('Estate', 'Lease held by an estate until transfer.'),
('Organization', 'Lease held by a religious or other organization.');

INSERT INTO ref_maintenance_types (type_name, description) VALUES
('Cleaning', 'General cleaning of the grave marker and plot.'),
('Floral Arrangement', 'Placement and maintenance of flowers.'),
('Monument Repair', 'Repair work on headstones or monuments.'),
('Gardening', 'Trimming shrubs, weeding, and general upkeep.'),
('Groundskeeping', 'General maintenance of the surrounding area.');

INSERT INTO ref_inspection_types (type_name, description) VALUES
('Annual Check', 'Routine yearly inspection.'),
('Damage Assessment', 'Inspection after reported damage.'),
('Historical Review', 'Special inspection for historical preservation.'),
('Safety Check', 'Inspection for structural stability and safety.');

-- =======================================================
-- Dummy Data for Core Tables
-- =======================================================

-- Cadastral Parcels (simplified for demo, 2 parcels covering the cemetery area)
INSERT INTO cadastral_parcels (parcel_number, owner, area_sqm, geom) VALUES
('123-456/1', 'Municipality', 5000.00, ST_GeomFromText('POLYGON((18.2080 49.8815, 18.2080 49.8830, 18.2095 49.8830, 18.2095 49.8815, 18.2080 49.8815))', 4326)),
('123-456/2', 'Cemetery Foundation', 7500.00, ST_GeomFromText('POLYGON((18.2095 49.8815, 18.2095 49.8830, 18.2105 49.8830, 18.2105 49.8815, 18.2095 49.8815))', 4326));

-- Graves
-- Helper function to generate slightly varied coordinates around a center point
CREATE OR REPLACE FUNCTION generate_grave_geom(center_lon DOUBLE PRECISION, center_lat DOUBLE PRECISION, offset_lon DOUBLE PRECISION, offset_lat DOUBLE PRECISION)
RETURNS geometry(POLYGON, 4326) AS $$
BEGIN
    RETURN ST_GeomFromText(
        'POLYGON((' ||
        (center_lon + offset_lon) || ' ' || (center_lat + offset_lat) || ', ' ||
        (center_lon + offset_lon) || ' ' || (center_lat + offset_lat + 0.00005) || ', ' ||
        (center_lon + offset_lon + 0.00005) || ' ' || (center_lat + offset_lat + 0.00005) || ', ' ||
        (center_lon + offset_lon + 0.00005) || ' ' || (center_lat + offset_lat) || ', ' ||
        (center_lon + offset_lon) || ' ' || (center_lat + offset_lat) ||
        '))', 4326
    );
END;
$$ LANGUAGE plpgsql;

-- Central coordinates for the cemetery area (adjust as needed for realistic placement)
-- Using the user's provided home point 49.88231, 18.20934
-- Note: ST_GeomFromText expects Longitude Latitude for WGS84 (4326)
DO $$
DECLARE
    center_lon DOUBLE PRECISION := 18.20934;
    center_lat DOUBLE PRECISION := 49.88231;
    section_a_id INT;
    section_b_id INT;
    section_c_id INT;
    grave_type_burial_id INT;
    grave_type_niche_id INT;
    grave_type_family_id INT;
    grave_condition_good_id INT;
    grave_condition_fair_id INT;
    grave_condition_poor_id INT;
    parcel_1_id INT;
    parcel_2_id INT;
    i INT;
BEGIN
    SELECT section_id INTO section_a_id FROM ref_cemetery_sections WHERE section_name = 'Section A - Old Grove';
    SELECT section_id INTO section_b_id FROM ref_cemetery_sections WHERE section_name = 'Section B - New Expansion';
    SELECT section_id INTO section_c_id FROM ref_cemetery_sections WHERE section_name = 'Section C - Lakeside View';

    SELECT type_id INTO grave_type_burial_id FROM ref_grave_types WHERE type_name = 'Burial';
    SELECT type_id INTO grave_type_niche_id FROM ref_grave_types WHERE type_name = 'Cremation Niche';
    SELECT type_id INTO grave_type_family_id FROM ref_grave_types WHERE type_name = 'Family Plot';

    SELECT condition_id INTO grave_condition_good_id FROM ref_grave_conditions WHERE condition_name = 'Good';
    SELECT condition_id INTO grave_condition_fair_id FROM ref_grave_conditions WHERE condition_name = 'Fair';
    SELECT condition_id INTO grave_condition_poor_id FROM ref_grave_conditions WHERE condition_name = 'Poor';

    SELECT parcel_id INTO parcel_1_id FROM cadastral_parcels WHERE parcel_number = '123-456/1';
    SELECT parcel_id INTO parcel_2_id FROM cadastral_parcels WHERE parcel_number = '123-456/2';

    -- 50 Graves
    FOR i IN 1..20 LOOP
        INSERT INTO graves (grave_number, section_id, grave_type_id, grave_condition_id, cadastral_parcel_id, geom, notes) VALUES
        (LPAD(i::TEXT, 2, '0'), section_a_id, grave_type_burial_id, grave_condition_good_id, parcel_1_id, generate_grave_geom(center_lon - 0.0003, center_lat - 0.0003 + (i * 0.0001), 0,0), 'Grave in old grove area.'),
        (LPAD((i+20)::TEXT, 2, '0'), section_b_id, grave_type_niche_id, grave_condition_fair_id, parcel_1_id, generate_grave_geom(center_lon + 0.0003, center_lat - 0.0003 + (i * 0.0001), 0,0), 'Niche in new expansion.'),
        (LPAD((i+40)::TEXT, 2, '0'), section_c_id, grave_type_family_id, grave_condition_poor_id, parcel_2_id, generate_grave_geom(center_lon + 0.0006, center_lat - 0.0003 + (i * 0.0001), 0,0), 'Family plot near lakeside.');
    END LOOP;
END $$;


-- Persons (80 deceased + some potential leaseholders)
INSERT INTO persons (first_name, last_name, birth_date, death_date, place_of_birth, place_of_death) VALUES
('Anna', 'Novakova', '1920-01-15', '1995-03-20', 'Prague', 'Ostrava'),
('Jan', 'Novak', '1918-05-10', '1990-11-01', 'Brno', 'Ostrava'),
('Petr', 'Svoboda', '1950-07-22', '2010-09-05', 'Ostrava', 'Ostrava'),
('Marie', 'Svobodova', '1955-02-28', '2015-06-12', 'Olomouc', 'Ostrava'),
('Karel', 'Dvorak', '1905-09-01', '1980-04-18', 'Plzen', 'Ostrava'),
('Eva', 'Dvorakova', '1908-12-05', '1985-08-25', 'Liberec', 'Ostrava'),
('Jana', 'Jelinka', '1970-03-01', NULL, 'Ostrava', NULL),
('Tomas', 'Jelinek', '1968-11-11', NULL, 'Ostrava', NULL),
('Josef', 'Prochazka', '1930-04-03', '2000-01-01', 'Ceske Budejovice', 'Ostrava'),
('Adela', 'Prochazkova', '1932-08-19', '2005-07-14', 'Ustí nad Labem', 'Ostrava'),
('Frantisek', 'Mares', '1945-10-20', '2018-02-09', 'Hradec Kralove', 'Ostrava'),
('Zuzana', 'Maresova', '1948-06-08', '2022-09-30', 'Pardubice', 'Ostrava'),
('David', 'Kolar', '1960-01-25', '2005-12-01', 'Zlín', 'Ostrava'),
('Olga', 'Kolarova', '1963-07-17', '2010-03-15', 'Karlovy Vary', 'Ostrava'),
('Pavel', 'Ruzicka', '1975-09-12', '2012-10-23', 'Jihlava', 'Ostrava'),
('Lenka', 'Ruzickova', '1978-04-04', '2019-01-07', 'Mlada Boleslav', 'Ostrava'),
('Monika', 'Kratochvilova', '1985-03-03', '2020-05-01', 'Opava', 'Ostrava'),
('Roman', 'Kratochvil', '1982-11-20', NULL, 'Frydek-Mistek', NULL),
('Stanislav', 'Vesely', '1900-02-02', '1970-06-15', 'Cesky Tesin', 'Ostrava'),
('Vera', 'Vesela', '1903-08-08', '1975-12-24', 'Havirov', 'Ostrava'),
('Daniel', 'Zeman', '1925-06-10', '1998-09-09', 'Karvina', 'Ostrava'),
('Kristyna', 'Zemanova', '1928-11-15', '2002-02-02', 'Orlova', 'Ostrava'),
('Lukas', 'Bila', '1940-01-01', '2008-07-07', 'Trinec', 'Ostrava'),
('Vendula', 'Bila', '1942-05-05', '2012-01-01', 'Novy Jicin', 'Ostrava'),
('Filip', 'Cerny', '1965-03-18', '2021-04-10', 'Prostejov', 'Ostrava'),
('Barbora', 'Cerna', '1967-09-23', NULL, 'Prerov', NULL),
('Miroslav', 'Benes', '1910-07-07', '1980-10-10', 'Znojmo', 'Ostrava'),
('Blanka', 'Benesova', '1912-11-11', '1988-03-03', 'Trebic', 'Ostrava'),
('Vojtech', 'Hajek', '1935-04-20', '2005-08-08', 'Kutna Hora', 'Ostrava'),
('Tereza', 'Hajkova', '1938-12-25', '2010-01-01', 'Pisek', 'Ostrava'),
('Jiri', 'Kovac', '1958-01-01', '2018-05-05', 'Kladno', 'Ostrava'),
('Alena', 'Kovacova', '1960-06-06', NULL, 'Most', NULL),
('Radek', 'Urban', '1922-03-22', '1999-07-17', 'Chomutov', 'Ostrava'),
('Sona', 'Urbanova', '1924-09-09', '2004-01-01', 'Teplice', 'Ostrava'),
('Petr', 'Janda', '1948-05-15', '2016-11-11', 'Usti nad Orlici', 'Ostrava'),
('Martina', 'Jandova', '1951-10-20', '2023-04-01', 'Svitavy', 'Ostrava'),
('Robert', 'Zeleny', '1970-12-01', NULL, 'Sumperk', NULL),
('Lucie', 'Zelena', '1972-06-06', NULL, 'Jesenik', NULL),
('Marek', 'Hruby', '1901-01-01', '1971-07-07', 'Bruntal', 'Ostrava'),
('Dana', 'Hrubá', '1904-05-05', '1978-11-11', 'Krnov', 'Ostrava'),
('Pavel', 'Nemec', '1930-08-10', '2002-02-20', 'Ostrava', 'Ostrava'),
('Hana', 'Nemcova', '1933-02-28', '2007-09-10', 'Ostrava', 'Ostrava'),
('Michal', 'Kubes', '1955-03-01', '2010-04-04', 'Ostrava', 'Ostrava'),
('Vlasta', 'Kubsova', '1958-09-09', '2015-10-10', 'Ostrava', 'Ostrava'),
('Jakub', 'Rybář', '1978-01-01', NULL, 'Ostrava', NULL),
('Petra', 'Rybářová', '1980-07-07', NULL, 'Ostrava', NULL);


-- Interments (3-4 persons per grave, filling up 50 graves minimum)
DO $$
DECLARE
    grave_rec RECORD;
    person_id1 INT;
    person_id2 INT;
    person_id3 INT;
    person_id4 INT;
    person_count INT := 1;
BEGIN
    FOR grave_rec IN SELECT grave_id FROM graves ORDER BY grave_id ASC LOOP
        -- Assign 2-3 deceased per grave
        SELECT person_id INTO person_id1 FROM persons OFFSET (person_count - 1) % 46 LIMIT 1;
        INSERT INTO interments (grave_id, person_id, date_of_interment) VALUES (grave_rec.grave_id, person_id1, (NOW() - ('100 year'::interval * random()))::DATE);
        
        IF random() > 0.3 THEN -- 70% chance for a second person
            SELECT person_id INTO person_id2 FROM persons OFFSET (person_count) % 46 LIMIT 1;
            INSERT INTO interments (grave_id, person_id, date_of_interment) VALUES (grave_rec.grave_id, person_id2, (NOW() - ('70 year'::interval * random()))::DATE);
        END IF;

        IF random() > 0.6 THEN -- 40% chance for a third person
            SELECT person_id INTO person_id3 FROM persons OFFSET (person_count + 1) % 46 LIMIT 1;
            INSERT INTO interments (grave_id, person_id, date_of_interment) VALUES (grave_rec.grave_id, person_id3, (NOW() - ('30 year'::interval * random()))::DATE);
        END IF;

        person_count := person_count + 3;
    END LOOP;
END $$;


-- Photos (1-2 photos per grave, some for persons)
DO $$
DECLARE
    grave_rec RECORD;
    person_rec RECORD;
    i INT := 1;
BEGIN
    FOR grave_rec IN SELECT grave_id FROM graves ORDER BY grave_id ASC LOOP
        INSERT INTO photos (grave_id, url, description, photo_date, taken_by) VALUES
        (grave_rec.grave_id, 'https://via.placeholder.com/150/0000FF/FFFFFF?text=Grave+' || grave_rec.grave_id || '+View', 'General view of grave ' || grave_rec.grave_number, (NOW() - ('5 year'::interval * random()))::DATE, 'Cemetery Admin');

        IF random() > 0.4 THEN -- 60% chance for a second photo
            INSERT INTO photos (grave_id, url, description, photo_date, taken_by) VALUES
            (grave_rec.grave_id, 'https://via.placeholder.com/150/FF0000/FFFFFF?text=Grave+' || grave_rec.grave_id || '+Detail', 'Detail of headstone ' || grave_rec.grave_number, (NOW() - ('2 year'::interval * random()))::DATE, 'Cemetery Admin');
        END IF;
    END LOOP;

    -- Add some photos for persons not directly tied to a grave (e.g., historical records)
    FOR person_rec IN SELECT person_id FROM persons OFFSET 5 LIMIT 5 LOOP
        INSERT INTO photos (person_id, url, description, photo_date, taken_by) VALUES
        (person_rec.person_id, 'https://via.placeholder.com/150/00FF00/FFFFFF?text=Person+' || person_rec.person_id + 100, 'Portrait of ' || person_rec.first_name || ' ' || person_rec.last_name, (NOW() - ('60 year'::interval * random()))::DATE, 'Family Archive');
    END LOOP;
END $$;

-- Leaseholders (mix of individuals and organizations)
DO $$
DECLARE
    person_id_jana INT;
    person_id_tomas INT;
    person_id_lucie INT;
    leaseholder_type_individual_id INT;
    leaseholder_type_family_id INT;
    leaseholder_type_org_id INT;
BEGIN
    SELECT person_id INTO person_id_jana FROM persons WHERE first_name = 'Jana' AND last_name = 'Jelinka';
    SELECT person_id INTO person_id_tomas FROM persons WHERE first_name = 'Tomas' AND last_name = 'Jelinek';
    SELECT person_id INTO person_id_lucie FROM persons WHERE first_name = 'Lucie' AND last_name = 'Zelena';

    SELECT leaseholder_type_id INTO leaseholder_type_individual_id FROM ref_leaseholder_types WHERE type_name = 'Individual';
    SELECT leaseholder_type_id INTO leaseholder_type_family_id FROM ref_leaseholder_types WHERE type_name = 'Family Representative';
    SELECT leaseholder_type_id INTO leaseholder_type_org_id FROM ref_leaseholder_types WHERE type_name = 'Organization';

    INSERT INTO leaseholders (person_id, leaseholder_type_id, contact_email, contact_phone, address) VALUES
    (person_id_jana, leaseholder_type_individual_id, 'jana.jelinka@example.com', '+420 777 123 456', 'Hlavní 1, Ostrava');
    
    INSERT INTO leaseholders (person_id, leaseholder_type_id, contact_email, contact_phone, address) VALUES
    (person_id_tomas, leaseholder_type_individual_id, 'tomas.jelinek@example.com', '+420 777 654 321', 'Nová 5, Ostrava');

    INSERT INTO leaseholders (organization_name, leaseholder_type_id, contact_email, contact_phone, address) VALUES
    ('Ostrava Historic Preservation', leaseholder_type_org_id, 'contact@oshp.org', '+420 596 123 789', 'Muzejní 10, Ostrava');

    INSERT INTO leaseholders (person_id, leaseholder_type_id, contact_email, contact_phone, address) VALUES
    (person_id_lucie, leaseholder_type_family_id, 'lucie.zelena@example.com', '+420 605 987 654', 'U hřbitova 15, Ostrava');

END $$;


-- Lease Contracts (assigning contracts to graves)
DO $$
DECLARE
    grave_rec RECORD;
    leaseholder_id1 INT;
    leaseholder_id2 INT;
    leaseholder_id3 INT;
    leaseholder_id4 INT;
    contract_start DATE;
    contract_end DATE;
    i INT := 1;
BEGIN
    SELECT leaseholder_id INTO leaseholder_id1 FROM leaseholders WHERE person_id = (SELECT person_id FROM persons WHERE first_name = 'Jana' AND last_name = 'Jelinka');
    SELECT leaseholder_id INTO leaseholder_id2 FROM leaseholders WHERE person_id = (SELECT person_id FROM persons WHERE first_name = 'Tomas' AND last_name = 'Jelinek');
    SELECT leaseholder_id INTO leaseholder_id3 FROM leaseholders WHERE organization_name = 'Ostrava Historic Preservation';
    SELECT leaseholder_id INTO leaseholder_id4 FROM leaseholders WHERE person_id = (SELECT person_id FROM persons WHERE first_name = 'Lucie' AND last_name = 'Zelena');

    FOR grave_rec IN SELECT grave_id FROM graves ORDER BY grave_id ASC LOOP
        contract_start := (NOW() - ('20 year'::interval * random()))::DATE;
        contract_end := contract_start + ('10 year'::interval * (1 + FLOOR(random() * 2))); -- 10 or 20 year contracts

        IF i % 4 = 1 THEN
            INSERT INTO lease_contracts (grave_id, leaseholder_id, start_date, end_date, contract_terms, renewal_date) VALUES
            (grave_rec.grave_id, leaseholder_id1, contract_start, contract_end, 'Standard 10-20 year lease.', contract_end - '1 month'::interval);
        ELSIF i % 4 = 2 THEN
            INSERT INTO lease_contracts (grave_id, leaseholder_id, start_date, end_date, contract_terms, renewal_date) VALUES
            (grave_rec.grave_id, leaseholder_id2, contract_start, contract_end, 'Standard 10-20 year lease with maintenance clause.', contract_end - '1 month'::interval);
        ELSIF i % 4 = 3 THEN
            INSERT INTO lease_contracts (grave_id, leaseholder_id, start_date, end_date, contract_terms, is_active) VALUES
            (grave_rec.grave_id, leaseholder_id3, contract_start, contract_start + '50 year'::interval, 'Historical preservation lease, very long term.', TRUE);
        ELSE
            INSERT INTO lease_contracts (grave_id, leaseholder_id, start_date, end_date, contract_terms, renewal_date) VALUES
            (grave_rec.grave_id, leaseholder_id4, contract_start, contract_end, 'Family plot lease, renewable every 10 years.', contract_end - '1 month'::interval);
        END IF;
        i := i + 1;
    END LOOP;
END $$;

-- Maintenance Records (for some graves)
DO $$
DECLARE
    grave_rec RECORD;
    maintenance_type_cleaning_id INT;
    maintenance_type_repair_id INT;
    maintenance_date DATE;
BEGIN
    SELECT maintenance_type_id INTO maintenance_type_cleaning_id FROM ref_maintenance_types WHERE type_name = 'Cleaning';
    SELECT maintenance_type_repair_id INTO maintenance_type_repair_id FROM ref_maintenance_types WHERE type_name = 'Monument Repair';

    FOR grave_rec IN SELECT grave_id FROM graves ORDER BY grave_id ASC LIMIT 30 LOOP -- First 30 graves get maintenance
        maintenance_date := (NOW() - ('1 year'::interval * random()))::DATE;
        INSERT INTO maintenance_records (grave_id, maintenance_type_id, maintenance_date, description, performed_by, cost) VALUES
        (grave_rec.grave_id, maintenance_type_cleaning_id, maintenance_date, 'Routine cleaning of headstone.', 'Cemetery Crew A', 50.00);
        
        IF random() > 0.7 THEN -- 30% chance for a repair
            maintenance_date := (NOW() - ('6 month'::interval * random()))::DATE;
            INSERT INTO maintenance_records (grave_id, maintenance_type_id, maintenance_date, description, performed_by, cost) VALUES
            (grave_rec.grave_id, maintenance_type_repair_id, maintenance_date, 'Minor crack repair on base.', 'Specialized Stoneworks', 350.00);
        END IF;
    END LOOP;
END $$;

-- Inspection Logs (for some graves)
DO $$
DECLARE
    grave_rec RECORD;
    inspection_type_annual_id INT;
    inspection_date DATE;
BEGIN
    SELECT inspection_type_id INTO inspection_type_annual_id FROM ref_inspection_types WHERE type_name = 'Annual Check';

    FOR grave_rec IN SELECT grave_id FROM graves ORDER BY grave_id ASC LIMIT 40 LOOP -- First 40 graves get inspections
        inspection_date := (NOW() - ('1 year'::interval * random()))::DATE;
        INSERT INTO inspection_logs (grave_id, inspection_type_id, inspection_date, inspector, condition_assessment, recommended_actions, next_inspection_date) VALUES
        (grave_rec.grave_id, inspection_type_annual_id, inspection_date, 'Inspector John', 'Overall good condition, some moss growth.', 'Schedule cleaning for spring.', inspection_date + '1 year'::interval);
        
        IF random() > 0.8 THEN -- 20% chance for a second, more recent inspection
            inspection_date := (NOW() - ('3 month'::interval * random()))::DATE;
            INSERT INTO inspection_logs (grave_id, inspection_type_id, inspection_date, inspector, condition_assessment, recommended_actions, next_inspection_date) VALUES
            (grave_rec.grave_id, inspection_type_annual_id, inspection_date, 'Inspector Jane', 'Moss cleaned, minor stone erosion noted.', 'Monitor stone erosion.', inspection_date + '1 year'::interval);
        END IF;
    END LOOP;
END $$;

-- Cemetery Infrastructure (example paths and water points)
INSERT INTO cemetery_infrastructure (infra_name, infra_type, description, geom) VALUES
('Main Path A1', 'Path', 'Primary path through Section A.', ST_GeomFromText('LINESTRING(18.2087 49.8820, 18.2087 49.8825)', 4326)),
('Main Path B1', 'Path', 'Primary path through Section B.', ST_GeomFromText('LINESTRING(18.2092 49.8820, 18.2092 49.8825)', 4326)),
('Water Point 1', 'Water Point', 'Water tap for visitors in Section A.', ST_GeomFromText('POINT(18.2088 49.8821)', 4326)),
('Water Point 2', 'Water Point', 'Water tap for visitors in Section B.', ST_GeomFromText('POINT(18.2093 49.8824)', 4326)),
('Boundary Fence West', 'Fence', 'Western perimeter fence.', ST_GeomFromText('LINESTRING(18.2085 49.8819, 18.2085 49.8826)', 4326));

-- Vegetation Inventory (example trees and shrubs)
INSERT INTO vegetation_inventory (common_name, scientific_name, planting_date, condition, geom) VALUES
('Oak Tree', 'Quercus robur', '1950-10-01', 'Healthy', ST_GeomFromText('POINT(18.2086 49.8821)', 4326)),
('Rose Bush', 'Rosa gallica', '2010-04-20', 'Good', ST_GeomFromText('POINT(18.2089 49.8823)', 4326)),
('Maple Tree', 'Acer platanoides', '1985-09-15', 'Healthy', ST_GeomFromText('POINT(18.2091 49.8822)', 4326));
