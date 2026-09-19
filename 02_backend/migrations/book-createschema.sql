--DROP SCHEMA IF EXISTS book;
--CREATE SCHEMA IF NOT EXISTS book;
--CREATE EXTENSION IF NOT EXISTS "uuid-ossp";



CREATE TABLE book.language_code (
	id serial4 PRIMARY KEY,
	code varchar NOT NULL,
	code_name varchar NOT NULL
);
COMMENT ON TABLE book.language_code IS 'ISO 639-1 Language Codes of the content''s language';

CREATE TABLE book.country_code (
	id serial4 PRIMARY KEY,
	code varchar NOT NULL,
	code_name varchar NOT NULL
);
COMMENT ON TABLE book.country_code IS 'ISO-3166 Country Codes';


CREATE TABLE book.title_type (
	id serial4 PRIMARY KEY,
	type_name varchar NOT null
);
COMMENT ON TABLE book.title_type IS 'A document can have several titles. e.g. main title, subtitle, original';


CREATE TABLE book.author_type (
	id serial4 PRIMARY KEY,
	author_type_name varchar NULL
);
COMMENT ON TABLE book.author_type IS 'The title of that person who worked on the book. e.g.: author, translator, illustrator';


CREATE TABLE book.genre (
	id serial4 PRIMARY KEY,
	genre_name varchar NOT null
);
COMMENT ON TABLE book.genre IS 'A document may contain several different genre designations';


CREATE TABLE book.media (
	id serial4 PRIMARY KEY,
	media_name varchar NOT null
);
COMMENT ON TABLE book.genre IS 'On which the document was printed or saved. e.g.: hardcover book, DVD';


CREATE TABLE book.keyword (
	id serial4 PRIMARY KEY,
	word varchar NOT null
);
COMMENT ON TABLE book.keyword IS 'search terms';


CREATE TABLE book.store (
	id serial4 PRIMARY KEY,
	store_name varchar null
);
COMMENT ON TABLE book.store IS 'room building or warehouse';


CREATE TABLE book.publisher (
id serial4 PRIMARY KEY,
publisher_name varchar null
);
COMMENT ON TABLE book.publisher IS 'publishing firms';






CREATE TABLE book.person (
	id serial4 PRIMARY KEY,
	nickname varchar NULL,
	prefix varchar NULL,
	forename varchar NULL,
	middle_name varchar NULL,
	surname varchar NULL,
	suffix varchar NULL,
	born date NULL,
	died date NULL,
	nationality_id int4 null,
	language_id int4 null,
	person_url varchar NULL,
	CONSTRAINT fk_person_language_id_language_code FOREIGN KEY (language_id) REFERENCES book.language_code(id),
	CONSTRAINT fk_person_nationality_id_country_code FOREIGN KEY (nationality_id) REFERENCES book.country_code(id)
);
COMMENT ON TABLE book.person IS 'A person who can be any type of author';



CREATE TABLE book.author (
	id serial4 PRIMARY KEY,
	author_type_id int4 not null,
	person_id int4 not null,
	CONSTRAINT fk_author_author_type_id_author_type FOREIGN KEY (author_type_id) REFERENCES book.author_type(id),
	CONSTRAINT fk_author_Person_id_person_id FOREIGN KEY (person_id) REFERENCES book.person(id)
);
COMMENT ON TABLE book.author IS 'A document can have several authors.';



CREATE TABLE book.doc (
	id serial4 PRIMARY KEY,
	language_id int4 null,
	year_origin int4,
	CONSTRAINT fk_doc_language_id_language_code FOREIGN KEY (language_id) REFERENCES book.language_code(id)
);
COMMENT ON TABLE book.doc IS 'it represents a creation';


CREATE TABLE book.genre_doc (
	id serial4 PRIMARY KEY,
	genre_id int4 NOT NULL,
	doc_id int4 NOT null,
	CONSTRAINT fk_genre_doc_genre_id_genre FOREIGN KEY (genre_id) REFERENCES book.genre(id),
	CONSTRAINT fk_genre_doc_doc_id_doc FOREIGN KEY (doc_id) REFERENCES book.doc(id)
);
COMMENT ON TABLE book.genre_doc IS 'Genre list of the document.';


CREATE TABLE book.author_doc (
	id serial4 PRIMARY KEY,
	author_id int4 NOT NULL,
	doc_id int4 NOT null,
	CONSTRAINT fk_author_doc_author_id_author FOREIGN KEY (author_id) REFERENCES book.author(id),
	CONSTRAINT fk_author_doc_doc_id_doc FOREIGN KEY (doc_id) REFERENCES book.doc(id)
);
COMMENT ON TABLE book.author_doc IS 'Authors of the document';


CREATE TABLE book.keyword_doc (
	id serial4 PRIMARY KEY,
	keyword_id int4 NOT NULL,
	doc_id int4 NOT null,
	CONSTRAINT fk_keyword_doc_keyword_id_keyword FOREIGN KEY (keyword_id) REFERENCES book.keyword(id),
	CONSTRAINT fk_keyword_doc_doc_id_doc FOREIGN KEY (doc_id) REFERENCES book.doc(id)
);
COMMENT ON TABLE book.keyword_doc IS 'Can be added searching keywords to the document.';



CREATE TABLE book.book_storage (
	id serial4 PRIMARY KEY,
	store_id int not null,
	storage_name varchar NULL,
	CONSTRAINT fk_book_storage_store_id_store FOREIGN KEY (store_id) REFERENCES book.store(id)
);
COMMENT ON TABLE book.book_storage IS 'furniture, shelf or box';



CREATE TABLE book.issue (
	id serial4 PRIMARY KEY,
	isbn varchar NULL,
	publishing date NULL,
	publishing_number int null,
	publishing_description varchar null,
	publisher_id int4 NULL,
	publishing_place varchar NULL,
	language_id int4 NOT null,
	media_id int4 not null,
	book_storage_id int4 not null,
	CONSTRAINT fk_issue_publisher_id_publisher FOREIGN KEY (publisher_id) REFERENCES book.publisher(id),
	CONSTRAINT fk_issue_language_id_language_code FOREIGN KEY (language_id) REFERENCES book.language_code(id),
	CONSTRAINT fk_issue_media_id_media FOREIGN KEY (media_id) REFERENCES book.media(id),
	CONSTRAINT fk_issue_book_storage_id_book_storage FOREIGN KEY (book_storage_id) REFERENCES book.book_storage(id)
);
COMMENT ON TABLE book.issue IS 'a published item';


CREATE TABLE book.issue_series (
	id serial4 PRIMARY KEY,
	isbn varchar null,
	publisher_id int4 NULL,
	description varchar null,
	CONSTRAINT fk_issue_series_publisher_id_publisher FOREIGN KEY (publisher_id) REFERENCES book.publisher(id)
);
COMMENT ON TABLE book.issue_series IS 'publisher''s book series e.g. "A Világirodalom Remekei" or "Jókai Összes Művei" or "Mikszáth Kálmán művei"';
COMMENT ON COLUMN book.issue_series.description IS 'may contain any additional info';


CREATE TABLE book.doc_series (
	id serial4 PRIMARY KEY,
	description varchar NULL
);
COMMENT ON TABLE book.doc_series IS 'A multi-part or continuous literary work, e.g. Ken Folett - Kingsbridge series or Bán Mór - Hunyadi';
COMMENT ON COLUMN book.doc_series.description IS 'may contain any additional info';


CREATE TABLE book.title (
	id serial4 PRIMARY KEY,
	language_id int4 NOT null,
	title varchar null,
	title_type_id int4 not null,
	CONSTRAINT fk_title_title_type_id_stitle_type FOREIGN KEY (title_type_id) REFERENCES book.title_type(id)
);
COMMENT ON TABLE book.title IS '';

CREATE TABLE book.doc_series_title (
	id serial4 PRIMARY KEY,
	series_id int4 NOT NULL,
	title_id int4 NOT null,
	CONSTRAINT fk_series_title_series_id_series FOREIGN KEY (series_id) REFERENCES book.doc_series(id),
	CONSTRAINT fk_series_title_title_id_title FOREIGN KEY (title_id) REFERENCES book.title(id)

);
COMMENT ON TABLE book.doc_series_title IS '';


CREATE TABLE book.doc_title (
	id serial4 PRIMARY KEY,
	doc_id int4 NOT NULL,
	title_id int4 NOT NULL,
	CONSTRAINT fk_doc_title_doc_id_doc FOREIGN KEY (doc_id) REFERENCES book.doc(id),
	CONSTRAINT fk_doc_title_title_id_title FOREIGN KEY (title_id) REFERENCES book.title(id)
);
COMMENT ON TABLE book.doc_title IS '';
