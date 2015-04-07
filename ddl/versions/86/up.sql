-- IMPORTANT: run script bin/combine_projects_with_different_sponsors.pl after this migration ---

alter table projects rename to old_projects;
alter table project_alleles rename to old_project_alleles;
alter table old_projects rename CONSTRAINT projects_pkey to old_projects_pkey;
alter table old_project_alleles rename constraint project_alleles_pkey to old_project_alleles_pkey;
alter sequence projects_id_seq rename to old_projects_id_seq;

-- Recreate the projects table without the sponsor_id

CREATE TABLE projects (
    id integer NOT NULL,
    gene_id text,
    targeting_type text DEFAULT 'unknown'::text NOT NULL,
    species_id text,
    htgt_project_id integer,
    effort_concluded boolean DEFAULT false NOT NULL,
    recovery_comment text,
    priority text,
    recovery_class_id integer
);

--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: lims2
--

CREATE SEQUENCE projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: lims2
--

ALTER SEQUENCE projects_id_seq OWNED BY projects.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: lims2
--

ALTER TABLE ONLY projects ALTER COLUMN id SET DEFAULT nextval('projects_id_seq'::regclass);

--
-- Name: projects_pkey; Type: CONSTRAINT; Schema: public; Owner: lims2; Tablespace:
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: sponsor_gene_type_species_key; Type: CONSTRAINT; Schema: public; Owner: lims2; Tablespace:
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT gene_type_species_key UNIQUE (gene_id, targeting_type, species_id);

--
-- Name: projects_recovery_class_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lims2
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_recovery_class_id_fkey FOREIGN KEY (recovery_class_id) REFERENCES project_recovery_class(id);

CREATE TABLE project_alleles (
    project_id integer NOT NULL,
    allele_type text NOT NULL,
    cassette_function text NOT NULL,
    mutation_type text NOT NULL
);


--
-- Name: project_alleles_pkey; Type: CONSTRAINT; Schema: public; Owner: lims2; Tablespace:
--

ALTER TABLE ONLY project_alleles
    ADD CONSTRAINT project_alleles_pkey PRIMARY KEY (project_id, allele_type);

--
-- Name: project_alleles_cassette_function_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lims2
--

ALTER TABLE ONLY project_alleles
    ADD CONSTRAINT project_alleles_cassette_function_fkey FOREIGN KEY (cassette_function) REFERENCES cassette_function(id);


--
-- Name: project_alleles_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: lims2
--

ALTER TABLE ONLY project_alleles
    ADD CONSTRAINT project_alleles_project_id_fkey FOREIGN KEY (project_id) REFERENCES projects(id);

-- Add the new table linking projects to sponsors through many to many relationship
create table project_sponsors (
   project_id integer not null references projects(id),
   sponsor_id text not null references sponsors(id)
);

alter table project_sponsors
    add CONSTRAINT project_sponsors_key UNIQUE (project_id, sponsor_id);

