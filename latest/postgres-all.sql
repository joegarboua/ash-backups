--
-- PostgreSQL database cluster dump
--

\restrict 2iaihpq698wjJN5hil4zyMjEwGR9m9EGNMd29sI59VKa7JxHlT8Ngawz6vz3h8O

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

--
-- Roles
--

CREATE ROLE agentyk;
ALTER ROLE agentyk WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION BYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:iNyFYZQgzqHfQEWhO41sPw==$ppkBPBA06bxdTFWb9KtFi0lYhGxcZ9t0dSav7BDKcZ0=:W4IXMv2EE1UYAbiHGk5+GbVooZ4y8DoH+O3heU/hMDk=';

--
-- User Configurations
--








\unrestrict 2iaihpq698wjJN5hil4zyMjEwGR9m9EGNMd29sI59VKa7JxHlT8Ngawz6vz3h8O

--
-- Databases
--

--
-- Database "template1" dump
--

\connect template1

--
-- PostgreSQL database dump
--

\restrict j9wzMka6bzgP5k75dGRkDOaJekFaiT7oNb665KxTeItVo0OMznazExiAucy28cq

-- Dumped from database version 16.13
-- Dumped by pg_dump version 16.13

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- PostgreSQL database dump complete
--

\unrestrict j9wzMka6bzgP5k75dGRkDOaJekFaiT7oNb665KxTeItVo0OMznazExiAucy28cq

--
-- Database "agentyk" dump
--

--
-- PostgreSQL database dump
--

\restrict nXYVQjnfhkAhvvmktvFYggbji0eTy5fjze3Tk0TPnZNOitMvo4xmKWjqDTJYfkn

-- Dumped from database version 16.13
-- Dumped by pg_dump version 16.13

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: agentyk; Type: DATABASE; Schema: -; Owner: agentyk
--

CREATE DATABASE agentyk WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';


ALTER DATABASE agentyk OWNER TO agentyk;

\unrestrict nXYVQjnfhkAhvvmktvFYggbji0eTy5fjze3Tk0TPnZNOitMvo4xmKWjqDTJYfkn
\connect agentyk
\restrict nXYVQjnfhkAhvvmktvFYggbji0eTy5fjze3Tk0TPnZNOitMvo4xmKWjqDTJYfkn

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: accounts; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.accounts (
    id integer NOT NULL,
    username text NOT NULL,
    email text NOT NULL,
    password_hash text NOT NULL,
    api_key text NOT NULL,
    status text DEFAULT 'pending_payment'::text NOT NULL,
    invoice_id text,
    expires_at timestamp with time zone,
    webhook_url text,
    quota_used integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    recovery_email text,
    forward_email text,
    whitelist_enabled boolean DEFAULT false,
    whitelist_emails text DEFAULT ''::text,
    recovery_seed_hash text DEFAULT ''::text,
    failed_login_attempts integer DEFAULT 0,
    locked_until timestamp with time zone
);


ALTER TABLE public.accounts OWNER TO agentyk;

--
-- Name: accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: agentyk
--

CREATE SEQUENCE public.accounts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.accounts_id_seq OWNER TO agentyk;

--
-- Name: accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: agentyk
--

ALTER SEQUENCE public.accounts_id_seq OWNED BY public.accounts.id;


--
-- Name: audit_log; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.audit_log (
    id integer NOT NULL,
    account_id integer,
    event_type text NOT NULL,
    ip_address text,
    details text,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.audit_log OWNER TO agentyk;

--
-- Name: audit_log_id_seq; Type: SEQUENCE; Schema: public; Owner: agentyk
--

CREATE SEQUENCE public.audit_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.audit_log_id_seq OWNER TO agentyk;

--
-- Name: audit_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: agentyk
--

ALTER SEQUENCE public.audit_log_id_seq OWNED BY public.audit_log.id;


--
-- Name: coupons; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.coupons (
    id integer NOT NULL,
    code text NOT NULL,
    duration_days integer DEFAULT 365 NOT NULL,
    created_by text DEFAULT 'system'::text NOT NULL,
    used_by integer,
    used_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.coupons OWNER TO agentyk;

--
-- Name: coupons_id_seq; Type: SEQUENCE; Schema: public; Owner: agentyk
--

CREATE SEQUENCE public.coupons_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.coupons_id_seq OWNER TO agentyk;

--
-- Name: coupons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: agentyk
--

ALTER SEQUENCE public.coupons_id_seq OWNED BY public.coupons.id;


--
-- Name: help_requests; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.help_requests (
    id integer NOT NULL,
    email text,
    invoice_id text,
    message text NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.help_requests OWNER TO agentyk;

--
-- Name: help_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: agentyk
--

CREATE SEQUENCE public.help_requests_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.help_requests_id_seq OWNER TO agentyk;

--
-- Name: help_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: agentyk
--

ALTER SEQUENCE public.help_requests_id_seq OWNED BY public.help_requests.id;


--
-- Name: mail_log; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.mail_log (
    id integer NOT NULL,
    account_id integer,
    direction text NOT NULL,
    from_addr text,
    to_addr text,
    subject text,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.mail_log OWNER TO agentyk;

--
-- Name: mail_log_id_seq; Type: SEQUENCE; Schema: public; Owner: agentyk
--

CREATE SEQUENCE public.mail_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mail_log_id_seq OWNER TO agentyk;

--
-- Name: mail_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: agentyk
--

ALTER SEQUENCE public.mail_log_id_seq OWNED BY public.mail_log.id;


--
-- Name: password_resets; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.password_resets (
    id integer NOT NULL,
    account_id integer,
    token text NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    used boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.password_resets OWNER TO agentyk;

--
-- Name: password_resets_id_seq; Type: SEQUENCE; Schema: public; Owner: agentyk
--

CREATE SEQUENCE public.password_resets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.password_resets_id_seq OWNER TO agentyk;

--
-- Name: password_resets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: agentyk
--

ALTER SEQUENCE public.password_resets_id_seq OWNED BY public.password_resets.id;


--
-- Name: payments; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.payments (
    id integer NOT NULL,
    account_id integer,
    invoice_id text NOT NULL,
    amount_eur numeric(10,2) NOT NULL,
    amount_btc text,
    status text DEFAULT 'pending'::text NOT NULL,
    btcpay_url text,
    paid_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.payments OWNER TO agentyk;

--
-- Name: payments_id_seq; Type: SEQUENCE; Schema: public; Owner: agentyk
--

CREATE SEQUENCE public.payments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payments_id_seq OWNER TO agentyk;

--
-- Name: payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: agentyk
--

ALTER SEQUENCE public.payments_id_seq OWNED BY public.payments.id;


--
-- Name: accounts id; Type: DEFAULT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.accounts ALTER COLUMN id SET DEFAULT nextval('public.accounts_id_seq'::regclass);


--
-- Name: audit_log id; Type: DEFAULT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.audit_log ALTER COLUMN id SET DEFAULT nextval('public.audit_log_id_seq'::regclass);


--
-- Name: coupons id; Type: DEFAULT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.coupons ALTER COLUMN id SET DEFAULT nextval('public.coupons_id_seq'::regclass);


--
-- Name: help_requests id; Type: DEFAULT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.help_requests ALTER COLUMN id SET DEFAULT nextval('public.help_requests_id_seq'::regclass);


--
-- Name: mail_log id; Type: DEFAULT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.mail_log ALTER COLUMN id SET DEFAULT nextval('public.mail_log_id_seq'::regclass);


--
-- Name: password_resets id; Type: DEFAULT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.password_resets ALTER COLUMN id SET DEFAULT nextval('public.password_resets_id_seq'::regclass);


--
-- Name: payments id; Type: DEFAULT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.payments ALTER COLUMN id SET DEFAULT nextval('public.payments_id_seq'::regclass);


--
-- Data for Name: accounts; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.accounts (id, username, email, password_hash, api_key, status, invoice_id, expires_at, webhook_url, quota_used, created_at, updated_at, recovery_email, forward_email, whitelist_enabled, whitelist_emails, recovery_seed_hash, failed_login_attempts, locked_until) FROM stdin;
48	audittest	audittest@agentyk.ru	$2a$10$QRPH4LBJAkoi0KcT.FYvmu4dQOzM58TG3D3305fdrC15OHeh0jcGy	ee5c6314-ad79-4717-8253-3ba275086e7d	pending_payment	inv_345fa220-44d1-4fa6-9089-d0217a4cc5d3	\N	\N	0	2026-03-09 18:00:14.722662+00	2026-03-09 18:00:14.740037+00	\N	\N	f		$2a$10$k5yacocRuUD7rafqpTAEl.9cLVsqzXpXJJQYc9b5QrW9fZNReTZXG	0	\N
51	neo	neo@agentyk.ru	$2a$10$F79O9xBpl/F98Kg.VpuvtOnEknBlvaSnikkqjx5YdUufIqWhzLe1W	e8b0fb0c-f131-479d-a628-4adeb90822f6	active	inv_e84b57c2-116a-41e4-9b80-cd01d2e107ad	2027-03-09 23:27:59.505835+00	\N	1	2026-03-09 23:27:53.251965+00	2026-03-09 23:28:38.488968+00	\N	\N	f		$2a$10$y0jETVuPwkdDVzuCDcUdMeEaT4lpOvqnbiBZFVC6Qy81MKbEFT.eu	0	\N
52	rex	rex@agentyk.ru	$2a$10$X3.CfmbblK1zSU4RRHgNAuLZjq4dKAIvQA4MDQh68PnFAikyKr3oy	6b1d7781-304f-4eec-9545-a4e6e3d1b8af	active	inv_c1a60c5e-f6f9-495b-aff8-3c240367b5b1	2027-03-09 23:30:08.164463+00	\N	7	2026-03-09 23:30:00.246249+00	2026-03-10 02:33:28.535642+00	\N	\N	f		$2a$10$yHrtxXUX/I6tQHM0FzTj9OgtSm.aboFVaoVOmncRzcMIvfaUQBn3K	0	\N
25	michel	michel@agentyk.ru	$2b$12$iGQ.Nm00PI9LrAXH7uryVeOuHFdVqa0Z89siXmmSDWr.cIXeIASMu	7523a432-1527-4620-8f81-5c7c0ff9e576	active	inv_0c3eeb7c	2027-03-08 00:03:48.781285+00	\N	0	2026-03-08 00:03:40.689802+00	2026-03-08 05:24:22.184148+00	\N	\N	f			0	\N
28	ra-sun	ra-sun@agentyk.ru	$2b$12$26Q38Yy6dTfmpLvh34xW7eDcmXHJ5ZXt3VskJbpB0OSYs8ftu8zWu	0ebe154f-ccf9-4c2e-a228-2ded04c62c0d	active	inv_a69a15f3	2027-03-08 03:58:49.709915+00	\N	1	2026-03-08 03:58:32.569812+00	2026-03-08 04:06:17.986386+00	\N	\N	f		$6$73b0625489135d65$a6866e35db8132aa97f5f3e7b451f146bcb714e4c0838634d1131eb5b3635ec6602fda330f7c0fc49de283e8f222b9e64a07b58b182187d44057d3c31b09fba3	0	\N
49	bit	bit@agentyk.ru	$2a$10$BR/JzEDMVFcY5u8HKcHS1ecsZMLE6CqmPvGdK3v8NFlGxsTXWVlrW	d7f938b7-4717-46a5-bf4f-9f0b3f7ff5ee	active	inv_787a721f-c2e0-46b7-a37e-02a0f44d7bcc	2027-03-09 18:34:45.560054+00	\N	5	2026-03-09 18:34:40.291506+00	2026-03-09 18:49:04.026697+00	\N	\N	f		$2a$10$rphKp8HIjkYcpMwJr5hoP.UTHZzVUYxgDzgMmD/tS8UShHOZKeLri	0	\N
26	doc	doc@agentyk.ru	$2b$12$6p1/Bw9J8kuIRVXcOGibY.uEtTjzlUr25kcxMhWj5p/SxXHtwiU3K	f0a93c76-4081-4e08-8a6e-6b1feba673d6	active	inv_fc5333e0	2027-03-08 00:39:52.48905+00	\N	5	2026-03-08 00:39:46.83973+00	2026-03-09 22:44:46.319479+00	josephgarboua@gmail.com	josephgarboua@gmail.com	f			0	\N
27	hon	hon@agentyk.ru	$2b$12$6PlYvGOq8wTMMyR46.JaROSADn8IYAbUIRr4TdK4SdRHN3F2Y1I0S	a2c5b84e-8d38-45fb-b302-abe8f96a928a	active	inv_9a80a82e	2028-03-07 03:20:07.561275+00	\N	2	2026-03-08 03:19:48.17881+00	2026-03-08 04:12:35.792043+00	micheldegeofroy@gmail.com	\N	f		$6$46653ce60c018ef4$089a4fb70e6633e12e2ad9c710be9c37f5c42ec33aed24eea03cf6ad87f2ace5d63179698676d0d493775240c818ba40b7b81e021ab288a832037b8b2b898112	0	\N
43	api	api@agentyk.ru	$2a$10$9Ae0QVAMDuIsyGr9uwZYh.lHnN6kYFS/y8e/9wvdg6lVU5AEjzggu	99ff0013-67ef-4a77-8259-0326696cba81	active	inv_6cdaa39d-5361-4af2-ab74-69e2f8e753ad	2027-03-09 17:51:53.727054+00	\N	4	2026-03-09 17:18:14.10549+00	2026-03-10 01:43:52.079229+00	\N	\N	f		$2a$10$K0FQ0NvNR7w7w/owLoVAQORwrj8/KjNlhJHC7s.ACQw8nUKOAVy3e	0	\N
50	ash	ash@agentyk.ru	$2a$10$32p3jbTkG5iP944qQkzcuu8HAC36I9UA6DRQC36vYgTL33.1G03sC	51bb956b-638b-4915-a82d-4f08a244bbea	active	inv_4fb10c38-b36b-41ce-b7cb-9dfe5028fe23	2027-03-09 18:47:07.038328+00	\N	16	2026-03-09 18:46:20.174779+00	2026-03-10 02:50:40.040649+00	\N	\N	f		$2a$10$3TY896qZ/8YwpSWyQLAalekZfydNIDbPH8pgTk7Cp7JACnLv3edNW	0	\N
\.


--
-- Data for Name: audit_log; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.audit_log (id, account_id, event_type, ip_address, details, created_at) FROM stdin;
13	43	account_created	46.225.1.128	api@agentyk.ru	2026-03-09 17:18:14.348777+00
14	\N	account_created	91.92.109.84	ashaudit01@agentyk.ru	2026-03-09 17:20:21.857833+00
15	\N	coupon_redeemed	91.92.109.84	coupon AYK-9725-39EB-DB77 (365d)	2026-03-09 17:20:22.790622+00
16	\N	login_success	91.92.109.84		2026-03-09 17:20:23.461701+00
17	\N	login_success	91.92.109.84		2026-03-09 17:20:23.950244+00
19	\N	account_created	91.92.109.84	ashaudit02@agentyk.ru	2026-03-09 17:45:21.037937+00
20	\N	coupon_redeemed	91.92.109.84	coupon AYK-63A3-ADAD-7969 (365d)	2026-03-09 17:45:21.418446+00
21	\N	login_success	91.92.109.84		2026-03-09 17:45:24.44232+00
22	\N	login_success	91.92.109.84		2026-03-09 17:45:24.804641+00
24	43	coupon_redeemed	46.225.1.128	coupon AYK-E6EC-706D-42DD (365d)	2026-03-09 17:51:53.754022+00
25	\N	account_created	91.92.109.84	ashfinal01@agentyk.ru	2026-03-09 17:55:06.202718+00
26	\N	login_success	91.92.109.84		2026-03-09 17:55:09.059308+00
27	\N	account_deleted	91.92.109.84	ashfinal01@agentyk.ru	2026-03-09 17:55:09.060336+00
28	\N	account_created	91.92.109.84	ashfinal02@agentyk.ru	2026-03-09 17:55:38.814764+00
29	\N	coupon_redeemed	91.92.109.84	coupon AYK-19BF-6B3E-E4C1 (365d)	2026-03-09 17:55:39.140393+00
30	\N	login_success	91.92.109.84		2026-03-09 17:55:41.822303+00
31	\N	account_deleted	91.92.109.84	ashfinal02@agentyk.ru	2026-03-09 17:55:41.825323+00
32	48	account_created	46.225.1.128	audittest@agentyk.ru	2026-03-09 18:00:14.973885+00
33	49	account_created	46.225.1.128	bit@agentyk.ru	2026-03-09 18:34:40.5003+00
34	49	coupon_redeemed	46.225.1.128	coupon AYK-049A-DCD8-B82C (365d)	2026-03-09 18:34:45.589966+00
35	50	account_created	::1	ash@agentyk.ru	2026-03-09 18:46:20.384644+00
36	50	coupon_redeemed	::1	coupon AYK-BBC8-8650-3C49 (365d)	2026-03-09 18:47:07.051575+00
37	51	account_created	46.225.1.128	neo@agentyk.ru	2026-03-09 23:27:53.46652+00
38	51	coupon_redeemed	46.225.1.128	coupon AYK-D03E-AF25-5301 (365d)	2026-03-09 23:27:59.518979+00
39	52	account_created	46.225.1.128	rex@agentyk.ru	2026-03-09 23:30:00.337226+00
40	52	coupon_redeemed	46.225.1.128	coupon AYK-BC62-4916-E892 (365d)	2026-03-09 23:30:08.172525+00
41	50	encryption_key_uploaded	172.18.0.1	PGP key uploaded for encryption at rest	2026-03-10 02:50:30.057636+00
42	50	encryption_disabled	172.18.0.1	Encryption at rest disabled	2026-03-10 02:51:13.469323+00
\.


--
-- Data for Name: coupons; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.coupons (id, code, duration_days, created_by, used_by, used_at, created_at) FROM stdin;
5	AYK-4E83-687B-91E8	365	father	\N	\N	2026-03-07 23:56:58.132478+00
4	AYK-8DF7-0DF7-EC71	365	father	25	2026-03-08 00:03:48.781285+00	2026-03-07 23:56:37.928414+00
7	AYK-C5C9-9B70-8A5B	365	father	26	2026-03-08 00:39:52.48905+00	2026-03-08 00:37:19.60434+00
8	AYK-4E18-5DFD-6CB8	365	father	27	2026-03-08 03:20:07.561275+00	2026-03-08 03:17:31.211562+00
9	AYK-DA26-A585-9B68	365	father	27	2026-03-08 03:52:59.144845+00	2026-03-08 03:49:27.892034+00
10	AYK-2AD1-34CC-D3EA	365	father	28	2026-03-08 03:58:49.709915+00	2026-03-08 03:54:22.272595+00
12	AYK-B06B-4156-3032	365	father	\N	\N	2026-03-08 05:34:21.293634+00
16	AYK-1504-9F0E-E7D1	365	father	\N	\N	2026-03-08 14:49:13.457853+00
17	AYK-6E6D-9ED2-1C8C	365	father	\N	\N	2026-03-08 16:17:44.101967+00
18	AYK-01B4-9FF9-B919	365	father	\N	\N	2026-03-09 17:20:03.468903+00
20	AYK-A093-E24F-0F2F	365	father	\N	\N	2026-03-09 17:20:03.468903+00
21	AYK-0150-B083-3E15	365	father	\N	\N	2026-03-09 17:20:03.468903+00
22	AYK-881E-EFFD-D4AE	365	father	\N	\N	2026-03-09 17:20:03.468903+00
23	AYK-FF8B-C533-0215	365	father	\N	\N	2026-03-09 17:20:03.468903+00
24	AYK-90DF-C2A5-CE08	365	father	\N	\N	2026-03-09 17:20:03.468903+00
25	AYK-1A85-6CAF-85F8	365	father	\N	\N	2026-03-09 17:20:03.468903+00
26	AYK-93AF-F3D3-71D5	365	father	\N	\N	2026-03-09 17:20:03.468903+00
27	AYK-CA9C-307B-245F	365	father	\N	\N	2026-03-09 17:20:03.468903+00
28	AYK-4501-1DC9-D632	365	father	\N	\N	2026-03-09 17:20:03.468903+00
34	AYK-2927-4A8E-74E0	365	father	\N	\N	2026-03-09 17:20:03.468903+00
35	AYK-AE6A-9BA8-D0ED	365	father	\N	\N	2026-03-09 17:20:03.468903+00
36	AYK-70C7-A411-AFBE	365	father	\N	\N	2026-03-09 17:20:03.468903+00
31	AYK-9725-39EB-DB77	365	father	\N	\N	2026-03-09 17:20:03.468903+00
30	AYK-63A3-ADAD-7969	365	father	\N	\N	2026-03-09 17:20:03.468903+00
29	AYK-E6EC-706D-42DD	365	father	43	2026-03-09 17:51:53.727054+00	2026-03-09 17:20:03.468903+00
38	AYK-D858-B1F5-18C3	365	father	\N	\N	2026-03-09 17:55:04.906871+00
19	AYK-19BF-6B3E-E4C1	365	father	\N	\N	2026-03-09 17:20:03.468903+00
39	AYK-0FEC-B270-7111	365	father	\N	\N	2026-03-09 17:55:52.400202+00
40	AYK-4A4F-4248-D62B	365	father	\N	\N	2026-03-09 17:55:52.400202+00
13	AYK-3400-F87B-2668	365	father	\N	\N	2026-03-08 12:14:39.459932+00
14	AYK-763B-BF2B-E433	365	father	\N	\N	2026-03-08 12:15:45.860682+00
15	AYK-392E-D3FF-9EAA	365	father	\N	\N	2026-03-08 12:33:58.114776+00
1	AYK-9D71-6FF2-E791	365	father	\N	\N	2026-03-07 20:12:21.091677+00
6	AYK-3ABE-10BF-DBCC	365	father	\N	\N	2026-03-08 00:00:37.783317+00
37	AYK-049A-DCD8-B82C	365	father	49	2026-03-09 18:34:45.560054+00	2026-03-09 17:20:03.468903+00
3	AYK-BBC8-8650-3C49	365	father	50	2026-03-09 18:47:07.038328+00	2026-03-07 20:12:21.543024+00
32	AYK-D03E-AF25-5301	365	father	51	2026-03-09 23:27:59.505835+00	2026-03-09 17:20:03.468903+00
33	AYK-BC62-4916-E892	365	father	52	2026-03-09 23:30:08.164463+00	2026-03-09 17:20:03.468903+00
\.


--
-- Data for Name: help_requests; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.help_requests (id, email, invoice_id, message, created_at) FROM stdin;
\.


--
-- Data for Name: mail_log; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.mail_log (id, account_id, direction, from_addr, to_addr, subject, created_at) FROM stdin;
\.


--
-- Data for Name: password_resets; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.password_resets (id, account_id, token, expires_at, used, created_at) FROM stdin;
\.


--
-- Data for Name: payments; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.payments (id, account_id, invoice_id, amount_eur, amount_btc, status, btcpay_url, paid_at, created_at) FROM stdin;
56	48	inv_345fa220-44d1-4fa6-9089-d0217a4cc5d3	60.00		pending		\N	2026-03-09 18:00:14.964499+00
57	49	inv_787a721f-c2e0-46b7-a37e-02a0f44d7bcc	60.00		paid		2026-03-09 18:34:45.560054+00	2026-03-09 18:34:40.496082+00
58	50	inv_4fb10c38-b36b-41ce-b7cb-9dfe5028fe23	60.00		paid		2026-03-09 18:47:07.038328+00	2026-03-09 18:46:20.379051+00
59	51	inv_e84b57c2-116a-41e4-9b80-cd01d2e107ad	60.00		paid		2026-03-09 23:27:59.505835+00	2026-03-09 23:27:53.447462+00
60	52	inv_c1a60c5e-f6f9-495b-aff8-3c240367b5b1	60.00		paid		2026-03-09 23:30:08.164463+00	2026-03-09 23:30:00.330552+00
25	25	inv_6e3be135	60.00		paid		2026-03-08 00:03:48.781285+00	2026-03-08 00:03:40.708312+00
26	26	inv_fc5333e0	60.00		paid		2026-03-08 00:39:52.48905+00	2026-03-08 00:39:46.866425+00
27	27	inv_85bdcfe6	60.00		paid		2026-03-08 03:20:07.561275+00	2026-03-08 03:19:48.224196+00
28	27	inv_9a80a82e	60.00		pending		\N	2026-03-08 03:22:15.974208+00
29	28	inv_a69a15f3	60.00		paid		2026-03-08 03:58:49.709915+00	2026-03-08 03:58:32.658487+00
32	25	inv_a37f623f	60.00		pending		\N	2026-03-08 05:24:14.994143+00
33	25	inv_0c3eeb7c	60.00		pending		\N	2026-03-08 05:24:22.184148+00
51	43	inv_6cdaa39d-5361-4af2-ab74-69e2f8e753ad	60.00		paid		2026-03-09 17:51:53.727054+00	2026-03-09 17:18:14.338074+00
\.


--
-- Name: accounts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: agentyk
--

SELECT pg_catalog.setval('public.accounts_id_seq', 52, true);


--
-- Name: audit_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: agentyk
--

SELECT pg_catalog.setval('public.audit_log_id_seq', 42, true);


--
-- Name: coupons_id_seq; Type: SEQUENCE SET; Schema: public; Owner: agentyk
--

SELECT pg_catalog.setval('public.coupons_id_seq', 40, true);


--
-- Name: help_requests_id_seq; Type: SEQUENCE SET; Schema: public; Owner: agentyk
--

SELECT pg_catalog.setval('public.help_requests_id_seq', 1, false);


--
-- Name: mail_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: agentyk
--

SELECT pg_catalog.setval('public.mail_log_id_seq', 1, false);


--
-- Name: password_resets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: agentyk
--

SELECT pg_catalog.setval('public.password_resets_id_seq', 1, false);


--
-- Name: payments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: agentyk
--

SELECT pg_catalog.setval('public.payments_id_seq', 60, true);


--
-- Name: accounts accounts_api_key_key; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_api_key_key UNIQUE (api_key);


--
-- Name: accounts accounts_email_key; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_email_key UNIQUE (email);


--
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: accounts accounts_username_key; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_username_key UNIQUE (username);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: coupons coupons_code_key; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.coupons
    ADD CONSTRAINT coupons_code_key UNIQUE (code);


--
-- Name: coupons coupons_pkey; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.coupons
    ADD CONSTRAINT coupons_pkey PRIMARY KEY (id);


--
-- Name: help_requests help_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.help_requests
    ADD CONSTRAINT help_requests_pkey PRIMARY KEY (id);


--
-- Name: mail_log mail_log_pkey; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.mail_log
    ADD CONSTRAINT mail_log_pkey PRIMARY KEY (id);


--
-- Name: password_resets password_resets_pkey; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.password_resets
    ADD CONSTRAINT password_resets_pkey PRIMARY KEY (id);


--
-- Name: password_resets password_resets_token_key; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.password_resets
    ADD CONSTRAINT password_resets_token_key UNIQUE (token);


--
-- Name: payments payments_invoice_id_key; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_invoice_id_key UNIQUE (invoice_id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: idx_accounts_api_key; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX idx_accounts_api_key ON public.accounts USING btree (api_key);


--
-- Name: idx_accounts_email; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX idx_accounts_email ON public.accounts USING btree (email);


--
-- Name: idx_accounts_expires_at; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX idx_accounts_expires_at ON public.accounts USING btree (expires_at);


--
-- Name: idx_accounts_invoice; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX idx_accounts_invoice ON public.accounts USING btree (invoice_id);


--
-- Name: idx_accounts_status; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX idx_accounts_status ON public.accounts USING btree (status);


--
-- Name: idx_audit_log_account_id; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX idx_audit_log_account_id ON public.audit_log USING btree (account_id);


--
-- Name: idx_audit_log_created_at; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX idx_audit_log_created_at ON public.audit_log USING btree (created_at);


--
-- Name: idx_audit_log_event_type; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX idx_audit_log_event_type ON public.audit_log USING btree (event_type);


--
-- Name: idx_coupons_code; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX idx_coupons_code ON public.coupons USING btree (code);


--
-- Name: idx_payments_invoice; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX idx_payments_invoice ON public.payments USING btree (invoice_id);


--
-- Name: idx_resets_token; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX idx_resets_token ON public.password_resets USING btree (token);


--
-- Name: audit_log audit_log_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE SET NULL;


--
-- Name: coupons coupons_used_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.coupons
    ADD CONSTRAINT coupons_used_by_fkey FOREIGN KEY (used_by) REFERENCES public.accounts(id);


--
-- Name: mail_log mail_log_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.mail_log
    ADD CONSTRAINT mail_log_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: password_resets password_resets_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.password_resets
    ADD CONSTRAINT password_resets_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: payments payments_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- PostgreSQL database dump complete
--

\unrestrict nXYVQjnfhkAhvvmktvFYggbji0eTy5fjze3Tk0TPnZNOitMvo4xmKWjqDTJYfkn

--
-- Database "btcpay" dump
--

--
-- PostgreSQL database dump
--

\restrict r7wckYNljaWhtD9ZzjGLevQeMnjm6IaHiOma1eALuQW7jcIOSxd5cJhhvtF1egn

-- Dumped from database version 16.13
-- Dumped by pg_dump version 16.13

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: btcpay; Type: DATABASE; Schema: -; Owner: agentyk
--

CREATE DATABASE btcpay WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';


ALTER DATABASE btcpay OWNER TO agentyk;

\unrestrict r7wckYNljaWhtD9ZzjGLevQeMnjm6IaHiOma1eALuQW7jcIOSxd5cJhhvtF1egn
\connect btcpay
\restrict r7wckYNljaWhtD9ZzjGLevQeMnjm6IaHiOma1eALuQW7jcIOSxd5cJhhvtF1egn

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: get_itemcode(jsonb); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.get_itemcode(invoice_blob jsonb) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT invoice_blob->'metadata'->>'itemCode';
$$;


ALTER FUNCTION public.get_itemcode(invoice_blob jsonb) OWNER TO agentyk;

--
-- Name: get_monitored_invoices(text, boolean); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.get_monitored_invoices(arg_payment_method_id text, include_non_activated boolean) RETURNS TABLE(invoice_id text, payment_id text, payment_method_id text)
    LANGUAGE sql STABLE
    AS $$
WITH cte AS (
-- Get all the invoices which are pending. Even if no payments.
SELECT i."Id" invoice_id, p."Id" payment_id, p."PaymentMethodId" payment_method_id FROM "Invoices" i LEFT JOIN "Payments" p ON i."Id" = p."InvoiceDataId"
        WHERE is_pending(i."Status")
UNION ALL
-- For invoices not pending, take all of those which have pending payments
SELECT i."Id" invoice_id, p."Id" payment_id, p."PaymentMethodId" payment_method_id FROM "Invoices" i INNER JOIN "Payments" p ON i."Id" = p."InvoiceDataId"
        WHERE is_pending(p."Status") AND NOT is_pending(i."Status"))
SELECT cte.* FROM cte
JOIN "Invoices" i ON cte.invoice_id=i."Id"
LEFT JOIN "Payments" p ON cte.payment_id=p."Id" AND cte.payment_method_id=p."PaymentMethodId"
WHERE (p."PaymentMethodId" IS NOT NULL AND p."PaymentMethodId" = arg_payment_method_id) OR
      (p."PaymentMethodId" IS NULL AND get_prompt(i."Blob2", arg_payment_method_id) IS NOT NULL AND
        (include_non_activated IS TRUE OR (get_prompt(i."Blob2", arg_payment_method_id)->'inactive')::BOOLEAN IS NOT TRUE));
$$;


ALTER FUNCTION public.get_monitored_invoices(arg_payment_method_id text, include_non_activated boolean) OWNER TO agentyk;

--
-- Name: get_orderid(jsonb); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.get_orderid(invoice_blob jsonb) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT invoice_blob->'metadata'->>'orderId';
$$;


ALTER FUNCTION public.get_orderid(invoice_blob jsonb) OWNER TO agentyk;

--
-- Name: get_prompt(jsonb, text); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.get_prompt(invoice_blob jsonb, payment_method_id text) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT invoice_blob->'prompts'->payment_method_id
$$;


ALTER FUNCTION public.get_prompt(invoice_blob jsonb, payment_method_id text) OWNER TO agentyk;

--
-- Name: is_pending(text); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.is_pending(status text) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT status = 'Processing' OR status = 'New';
$$;


ALTER FUNCTION public.is_pending(status text) OWNER TO agentyk;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: AddressInvoices; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."AddressInvoices" (
    "Address" text NOT NULL,
    "InvoiceDataId" text,
    "PaymentMethodId" text DEFAULT ''::text NOT NULL
);


ALTER TABLE public."AddressInvoices" OWNER TO agentyk;

--
-- Name: ApiKeys; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."ApiKeys" (
    "Id" character varying(50) NOT NULL,
    "StoreId" character varying(50),
    "Type" integer DEFAULT 0 NOT NULL,
    "UserId" character varying(50),
    "Label" text,
    "Blob" bytea,
    "Blob2" jsonb
);


ALTER TABLE public."ApiKeys" OWNER TO agentyk;

--
-- Name: Apps; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."Apps" (
    "Id" text NOT NULL,
    "AppType" text,
    "Created" timestamp with time zone NOT NULL,
    "Name" text,
    "Settings" jsonb,
    "StoreDataId" text,
    "TagAllInvoices" boolean DEFAULT false NOT NULL,
    "Archived" boolean DEFAULT false NOT NULL
);


ALTER TABLE public."Apps" OWNER TO agentyk;

--
-- Name: AspNetRoleClaims; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."AspNetRoleClaims" (
    "Id" integer NOT NULL,
    "ClaimType" text,
    "ClaimValue" text,
    "RoleId" text NOT NULL
);


ALTER TABLE public."AspNetRoleClaims" OWNER TO agentyk;

--
-- Name: AspNetRoles; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."AspNetRoles" (
    "Id" text NOT NULL,
    "ConcurrencyStamp" text,
    "Name" character varying(256),
    "NormalizedName" character varying(256)
);


ALTER TABLE public."AspNetRoles" OWNER TO agentyk;

--
-- Name: AspNetUserClaims; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."AspNetUserClaims" (
    "Id" integer NOT NULL,
    "ClaimType" text,
    "ClaimValue" text,
    "UserId" text NOT NULL
);


ALTER TABLE public."AspNetUserClaims" OWNER TO agentyk;

--
-- Name: AspNetUserLogins; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."AspNetUserLogins" (
    "LoginProvider" character varying(255) NOT NULL,
    "ProviderKey" character varying(255) NOT NULL,
    "ProviderDisplayName" text,
    "UserId" text NOT NULL
);


ALTER TABLE public."AspNetUserLogins" OWNER TO agentyk;

--
-- Name: AspNetUserRoles; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."AspNetUserRoles" (
    "UserId" text NOT NULL,
    "RoleId" text NOT NULL
);


ALTER TABLE public."AspNetUserRoles" OWNER TO agentyk;

--
-- Name: AspNetUserTokens; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."AspNetUserTokens" (
    "UserId" text NOT NULL,
    "LoginProvider" character varying(64) NOT NULL,
    "Name" character varying(64) NOT NULL,
    "Value" text
);


ALTER TABLE public."AspNetUserTokens" OWNER TO agentyk;

--
-- Name: AspNetUsers; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."AspNetUsers" (
    "Id" text NOT NULL,
    "AccessFailedCount" integer NOT NULL,
    "ConcurrencyStamp" text,
    "Email" character varying(256),
    "EmailConfirmed" boolean NOT NULL,
    "LockoutEnabled" boolean NOT NULL,
    "LockoutEnd" timestamp with time zone,
    "NormalizedEmail" character varying(256),
    "NormalizedUserName" character varying(256),
    "PasswordHash" text,
    "PhoneNumber" text,
    "PhoneNumberConfirmed" boolean NOT NULL,
    "SecurityStamp" text,
    "TwoFactorEnabled" boolean NOT NULL,
    "UserName" character varying(256),
    "RequiresEmailConfirmation" boolean DEFAULT false NOT NULL,
    "Created" timestamp with time zone,
    "DisabledNotifications" text,
    "Blob" bytea,
    "Blob2" jsonb,
    "Approved" boolean DEFAULT false NOT NULL,
    "RequiresApproval" boolean DEFAULT false NOT NULL
);


ALTER TABLE public."AspNetUsers" OWNER TO agentyk;

--
-- Name: Fido2Credentials; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."Fido2Credentials" (
    "Id" text NOT NULL,
    "Name" text,
    "ApplicationUserId" text,
    "Blob" bytea,
    "Type" integer NOT NULL,
    "Blob2" jsonb
);


ALTER TABLE public."Fido2Credentials" OWNER TO agentyk;

--
-- Name: Files; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."Files" (
    "Id" text NOT NULL,
    "FileName" text,
    "StorageFileName" text,
    "Timestamp" timestamp with time zone NOT NULL,
    "ApplicationUserId" text
);


ALTER TABLE public."Files" OWNER TO agentyk;

--
-- Name: Forms; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."Forms" (
    "Id" text NOT NULL,
    "Name" text,
    "StoreId" text,
    "Config" jsonb,
    "Public" boolean NOT NULL
);


ALTER TABLE public."Forms" OWNER TO agentyk;

--
-- Name: InvoiceEvents; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."InvoiceEvents" (
    "InvoiceDataId" text NOT NULL,
    "Message" text,
    "Timestamp" timestamp with time zone NOT NULL,
    "Severity" integer DEFAULT 0 NOT NULL
);


ALTER TABLE public."InvoiceEvents" OWNER TO agentyk;

--
-- Name: InvoiceSearches; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."InvoiceSearches" (
    "Id" integer NOT NULL,
    "InvoiceDataId" character varying(255),
    "Value" text
);


ALTER TABLE public."InvoiceSearches" OWNER TO agentyk;

--
-- Name: InvoiceSearches_Id_seq; Type: SEQUENCE; Schema: public; Owner: agentyk
--

CREATE SEQUENCE public."InvoiceSearches_Id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."InvoiceSearches_Id_seq" OWNER TO agentyk;

--
-- Name: InvoiceSearches_Id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: agentyk
--

ALTER SEQUENCE public."InvoiceSearches_Id_seq" OWNED BY public."InvoiceSearches"."Id";


--
-- Name: InvoiceWebhookDeliveries; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."InvoiceWebhookDeliveries" (
    "InvoiceId" text NOT NULL,
    "DeliveryId" text NOT NULL
);


ALTER TABLE public."InvoiceWebhookDeliveries" OWNER TO agentyk;

--
-- Name: Invoices; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."Invoices" (
    "Id" text NOT NULL,
    "Blob" bytea,
    "Created" timestamp with time zone NOT NULL,
    "ExceptionStatus" text,
    "Status" text,
    "StoreDataId" text,
    "Archived" boolean DEFAULT false NOT NULL,
    "Blob2" jsonb,
    "Amount" numeric,
    "Currency" text
);


ALTER TABLE public."Invoices" OWNER TO agentyk;

--
-- Name: LightningAddresses; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."LightningAddresses" (
    "Username" text NOT NULL,
    "StoreDataId" text NOT NULL,
    "Blob" bytea,
    "Blob2" jsonb
);


ALTER TABLE public."LightningAddresses" OWNER TO agentyk;

--
-- Name: Notifications; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."Notifications" (
    "Id" character varying(36) NOT NULL,
    "Created" timestamp with time zone NOT NULL,
    "ApplicationUserId" character varying(50) NOT NULL,
    "NotificationType" character varying(100) NOT NULL,
    "Seen" boolean NOT NULL,
    "Blob" bytea,
    "Blob2" jsonb
);


ALTER TABLE public."Notifications" OWNER TO agentyk;

--
-- Name: OffchainTransactions; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."OffchainTransactions" (
    "Id" character varying(64) NOT NULL,
    "Blob" bytea
);


ALTER TABLE public."OffchainTransactions" OWNER TO agentyk;

--
-- Name: PairedSINData; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."PairedSINData" (
    "Id" text NOT NULL,
    "Label" text,
    "PairingTime" timestamp with time zone NOT NULL,
    "SIN" text,
    "StoreDataId" text
);


ALTER TABLE public."PairedSINData" OWNER TO agentyk;

--
-- Name: PairingCodes; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."PairingCodes" (
    "Id" text NOT NULL,
    "DateCreated" timestamp with time zone NOT NULL,
    "Expiration" timestamp with time zone NOT NULL,
    "Facade" text,
    "Label" text,
    "SIN" text,
    "StoreDataId" text,
    "TokenValue" text
);


ALTER TABLE public."PairingCodes" OWNER TO agentyk;

--
-- Name: PayjoinLocks; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."PayjoinLocks" (
    "Id" character varying(100) NOT NULL
);


ALTER TABLE public."PayjoinLocks" OWNER TO agentyk;

--
-- Name: PaymentRequests; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."PaymentRequests" (
    "Id" text NOT NULL,
    "StoreDataId" text,
    "Blob" bytea,
    "Created" timestamp with time zone DEFAULT '1970-01-01 00:00:00+00'::timestamp with time zone NOT NULL,
    "Archived" boolean DEFAULT false NOT NULL,
    "Blob2" jsonb,
    "ReferenceId" text,
    "Expiry" timestamp with time zone,
    "Amount" numeric DEFAULT 0.0 NOT NULL,
    "Currency" text,
    "Status" text NOT NULL,
    "Title" text
);


ALTER TABLE public."PaymentRequests" OWNER TO agentyk;

--
-- Name: Payments; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."Payments" (
    "Id" text NOT NULL,
    "Blob" bytea,
    "InvoiceDataId" text,
    "Accounted" boolean DEFAULT false,
    "Blob2" jsonb,
    "PaymentMethodId" text NOT NULL,
    "Amount" numeric,
    "Created" timestamp with time zone,
    "Currency" text,
    "Status" text
);


ALTER TABLE public."Payments" OWNER TO agentyk;

--
-- Name: PayoutProcessors; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."PayoutProcessors" (
    "Id" text NOT NULL,
    "StoreId" text,
    "PayoutMethodId" text,
    "Processor" text,
    "Blob" bytea,
    "Blob2" jsonb
);


ALTER TABLE public."PayoutProcessors" OWNER TO agentyk;

--
-- Name: Payouts; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."Payouts" (
    "Id" character varying(30) NOT NULL,
    "Date" timestamp with time zone NOT NULL,
    "PullPaymentDataId" character varying(30),
    "State" character varying(20) NOT NULL,
    "PayoutMethodId" character varying(20) NOT NULL,
    "DedupId" text,
    "Blob" jsonb,
    "Proof" jsonb,
    "StoreDataId" text,
    "Currency" text NOT NULL,
    "Amount" numeric,
    "OriginalAmount" numeric NOT NULL,
    "OriginalCurrency" text NOT NULL
);


ALTER TABLE public."Payouts" OWNER TO agentyk;

--
-- Name: PendingTransactions; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."PendingTransactions" (
    "TransactionId" text,
    "CryptoCode" text,
    "StoreId" text,
    "Expiry" timestamp with time zone,
    "State" integer NOT NULL,
    "OutpointsUsed" text[],
    "Blob2" jsonb,
    "Id" text DEFAULT ''::text NOT NULL
);


ALTER TABLE public."PendingTransactions" OWNER TO agentyk;

--
-- Name: PlannedTransactions; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."PlannedTransactions" (
    "Id" character varying(100) NOT NULL,
    "BroadcastAt" timestamp with time zone NOT NULL,
    "Blob" bytea
);


ALTER TABLE public."PlannedTransactions" OWNER TO agentyk;

--
-- Name: PullPayments; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."PullPayments" (
    "Id" character varying(30) NOT NULL,
    "StoreId" character varying(50),
    "StartDate" timestamp with time zone NOT NULL,
    "EndDate" timestamp with time zone,
    "Archived" boolean NOT NULL,
    "Blob" jsonb,
    "Currency" text NOT NULL,
    "Limit" numeric NOT NULL
);


ALTER TABLE public."PullPayments" OWNER TO agentyk;

--
-- Name: Refunds; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."Refunds" (
    "InvoiceDataId" text NOT NULL,
    "PullPaymentDataId" text NOT NULL
);


ALTER TABLE public."Refunds" OWNER TO agentyk;

--
-- Name: Settings; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."Settings" (
    "Id" text NOT NULL,
    "Value" jsonb
);


ALTER TABLE public."Settings" OWNER TO agentyk;

--
-- Name: StoreRoles; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."StoreRoles" (
    "Id" text NOT NULL,
    "StoreDataId" text,
    "Role" text NOT NULL,
    "Permissions" text[] NOT NULL
);


ALTER TABLE public."StoreRoles" OWNER TO agentyk;

--
-- Name: StoreSettings; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."StoreSettings" (
    "Name" text NOT NULL,
    "StoreId" text NOT NULL,
    "Value" jsonb
);


ALTER TABLE public."StoreSettings" OWNER TO agentyk;

--
-- Name: StoreWebhooks; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."StoreWebhooks" (
    "StoreId" character varying(50) NOT NULL,
    "WebhookId" character varying(25) NOT NULL
);


ALTER TABLE public."StoreWebhooks" OWNER TO agentyk;

--
-- Name: Stores; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."Stores" (
    "Id" text NOT NULL,
    "DerivationStrategy" text,
    "SpeedPolicy" integer NOT NULL,
    "StoreCertificate" bytea,
    "StoreName" text,
    "StoreWebsite" text,
    "StoreBlob" jsonb,
    "DerivationStrategies" jsonb,
    "DefaultCrypto" text,
    "Archived" boolean DEFAULT false NOT NULL
);


ALTER TABLE public."Stores" OWNER TO agentyk;

--
-- Name: U2FDevices; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."U2FDevices" (
    "Id" text NOT NULL,
    "Name" text,
    "KeyHandle" bytea NOT NULL,
    "PublicKey" bytea NOT NULL,
    "AttestationCert" bytea NOT NULL,
    "Counter" integer NOT NULL,
    "ApplicationUserId" text
);


ALTER TABLE public."U2FDevices" OWNER TO agentyk;

--
-- Name: UserStore; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."UserStore" (
    "ApplicationUserId" text NOT NULL,
    "StoreDataId" text NOT NULL,
    "Role" text
);


ALTER TABLE public."UserStore" OWNER TO agentyk;

--
-- Name: WalletObjectLinks; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."WalletObjectLinks" (
    "WalletId" text NOT NULL,
    "AType" text NOT NULL,
    "AId" text NOT NULL,
    "BType" text NOT NULL,
    "BId" text NOT NULL,
    "Data" jsonb
);


ALTER TABLE public."WalletObjectLinks" OWNER TO agentyk;

--
-- Name: WalletObjects; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."WalletObjects" (
    "WalletId" text NOT NULL,
    "Type" text NOT NULL,
    "Id" text NOT NULL,
    "Data" jsonb
);


ALTER TABLE public."WalletObjects" OWNER TO agentyk;

--
-- Name: WalletTransactions; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."WalletTransactions" (
    "WalletDataId" text NOT NULL,
    "TransactionId" text NOT NULL,
    "Labels" text,
    "Blob" bytea
);


ALTER TABLE public."WalletTransactions" OWNER TO agentyk;

--
-- Name: Wallets; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."Wallets" (
    "Id" text NOT NULL,
    "Blob" bytea
);


ALTER TABLE public."Wallets" OWNER TO agentyk;

--
-- Name: WebhookDeliveries; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."WebhookDeliveries" (
    "Id" text NOT NULL,
    "WebhookId" text NOT NULL,
    "Timestamp" timestamp with time zone NOT NULL,
    "Pruned" boolean NOT NULL,
    "Blob" jsonb NOT NULL,
    "DeliveryTime" timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public."WebhookDeliveries" OWNER TO agentyk;

--
-- Name: Webhooks; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."Webhooks" (
    "Id" character varying(25) NOT NULL,
    "Blob" bytea NOT NULL,
    "Blob2" jsonb
);


ALTER TABLE public."Webhooks" OWNER TO agentyk;

--
-- Name: __EFMigrationsHistory; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public."__EFMigrationsHistory" (
    "MigrationId" character varying(150) NOT NULL,
    "ProductVersion" character varying(32) NOT NULL
);


ALTER TABLE public."__EFMigrationsHistory" OWNER TO agentyk;

--
-- Name: boltcards; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.boltcards (
    id character varying(32) NOT NULL,
    counter integer DEFAULT 0 NOT NULL,
    ppid character varying(30),
    version integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.boltcards OWNER TO agentyk;

--
-- Name: customers; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.customers (
    id text NOT NULL,
    store_id text NOT NULL,
    external_ref text,
    name text DEFAULT ''::text NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    additional_data jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.customers OWNER TO agentyk;

--
-- Name: customers_identities; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.customers_identities (
    customer_id text NOT NULL,
    type text NOT NULL,
    value text NOT NULL
);


ALTER TABLE public.customers_identities OWNER TO agentyk;

--
-- Name: email_rules; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.email_rules (
    "Id" bigint NOT NULL,
    store_id text,
    trigger text NOT NULL,
    condition text,
    "to" text[] NOT NULL,
    subject text DEFAULT ''::text NOT NULL,
    body text NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    additional_data jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    offering_id text,
    bcc text[] DEFAULT ARRAY[]::text[] NOT NULL,
    cc text[] DEFAULT ARRAY[]::text[] NOT NULL
);


ALTER TABLE public.email_rules OWNER TO agentyk;

--
-- Name: email_rules_Id_seq; Type: SEQUENCE; Schema: public; Owner: agentyk
--

ALTER TABLE public.email_rules ALTER COLUMN "Id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public."email_rules_Id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: lang_dictionaries; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.lang_dictionaries (
    dict_id text NOT NULL,
    fallback text,
    source text,
    metadata jsonb
);


ALTER TABLE public.lang_dictionaries OWNER TO agentyk;

--
-- Name: lang_translations; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.lang_translations (
    dict_id text NOT NULL,
    sentence text NOT NULL,
    translation text NOT NULL
);


ALTER TABLE public.lang_translations OWNER TO agentyk;

--
-- Name: store_label_links; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.store_label_links (
    store_id text NOT NULL,
    store_label_id text NOT NULL,
    object_id text NOT NULL
);


ALTER TABLE public.store_label_links OWNER TO agentyk;

--
-- Name: store_labels; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.store_labels (
    store_id text NOT NULL,
    id text NOT NULL,
    type text NOT NULL,
    text text NOT NULL,
    color text
);


ALTER TABLE public.store_labels OWNER TO agentyk;

--
-- Name: subs_features; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.subs_features (
    id bigint NOT NULL,
    custom_id text NOT NULL,
    offering_id text NOT NULL,
    description text
);


ALTER TABLE public.subs_features OWNER TO agentyk;

--
-- Name: subs_features_id_seq; Type: SEQUENCE; Schema: public; Owner: agentyk
--

ALTER TABLE public.subs_features ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.subs_features_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: subs_offerings; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.subs_offerings (
    id text NOT NULL,
    app_id text NOT NULL,
    success_redirect_url text,
    payment_reminder_days integer DEFAULT 3 NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    additional_data jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.subs_offerings OWNER TO agentyk;

--
-- Name: subs_plan_changes; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.subs_plan_changes (
    plan_id text NOT NULL,
    plan_change_id text NOT NULL,
    type text NOT NULL
);


ALTER TABLE public.subs_plan_changes OWNER TO agentyk;

--
-- Name: subs_plan_checkouts; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.subs_plan_checkouts (
    id text NOT NULL,
    invoice_id text,
    success_redirect_url text,
    is_trial boolean DEFAULT false NOT NULL,
    plan_id text NOT NULL,
    new_subscriber boolean NOT NULL,
    new_subscriber_email text,
    subscriber_id bigint,
    invoice_metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    new_subscriber_metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    test_account boolean NOT NULL,
    credited numeric NOT NULL,
    plan_started boolean NOT NULL,
    credit_purchase numeric,
    refund_amount numeric,
    on_pay text DEFAULT 'SoftMigration'::text NOT NULL,
    base_url text NOT NULL,
    expiration timestamp with time zone DEFAULT (now() + '1 day'::interval) NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    additional_data jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.subs_plan_checkouts OWNER TO agentyk;

--
-- Name: subs_plans; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.subs_plans (
    id text NOT NULL,
    offering_id text NOT NULL,
    name text NOT NULL,
    status text NOT NULL,
    price numeric NOT NULL,
    currency text NOT NULL,
    recurring_type text NOT NULL,
    grace_period_days integer NOT NULL,
    trial_days integer NOT NULL,
    description text,
    members_count integer NOT NULL,
    monthly_revenue numeric NOT NULL,
    optimistic_activation boolean DEFAULT false NOT NULL,
    renewable boolean DEFAULT true NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    additional_data jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.subs_plans OWNER TO agentyk;

--
-- Name: subs_plans_features; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.subs_plans_features (
    plan_id text NOT NULL,
    feature_id bigint NOT NULL
);


ALTER TABLE public.subs_plans_features OWNER TO agentyk;

--
-- Name: subs_portal_sessions; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.subs_portal_sessions (
    id text NOT NULL,
    subscriber_id bigint NOT NULL,
    expiration timestamp with time zone DEFAULT (now() + '1 day'::interval) NOT NULL,
    base_url text NOT NULL
);


ALTER TABLE public.subs_portal_sessions OWNER TO agentyk;

--
-- Name: subs_subscriber_credits; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.subs_subscriber_credits (
    subscriber_id bigint NOT NULL,
    currency text NOT NULL,
    amount numeric NOT NULL
);


ALTER TABLE public.subs_subscriber_credits OWNER TO agentyk;

--
-- Name: subs_subscriber_credits_history; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.subs_subscriber_credits_history (
    "Id" bigint NOT NULL,
    subscriber_id bigint NOT NULL,
    currency text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    description text NOT NULL,
    debit numeric NOT NULL,
    credit numeric NOT NULL,
    balance numeric NOT NULL
);


ALTER TABLE public.subs_subscriber_credits_history OWNER TO agentyk;

--
-- Name: subs_subscriber_credits_history_Id_seq; Type: SEQUENCE; Schema: public; Owner: agentyk
--

ALTER TABLE public.subs_subscriber_credits_history ALTER COLUMN "Id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public."subs_subscriber_credits_history_Id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: subs_subscribers; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.subs_subscribers (
    id bigint NOT NULL,
    offering_id text NOT NULL,
    customer_id text NOT NULL,
    plan_id text NOT NULL,
    new_plan_id text,
    paid_amount numeric,
    processing_invoice_id text,
    phase text DEFAULT 'Expired'::text NOT NULL,
    plan_started timestamp with time zone DEFAULT now() NOT NULL,
    period_end timestamp with time zone,
    optimistic_activation boolean NOT NULL,
    trial_end timestamp with time zone,
    grace_period_end timestamp with time zone,
    auto_renew boolean DEFAULT true NOT NULL,
    active boolean DEFAULT false NOT NULL,
    payment_reminder_days integer,
    payment_reminded boolean DEFAULT false NOT NULL,
    suspended boolean DEFAULT false NOT NULL,
    test_account boolean DEFAULT false NOT NULL,
    suspension_reason text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    additional_data jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    reminder_date timestamp with time zone
);


ALTER TABLE public.subs_subscribers OWNER TO agentyk;

--
-- Name: subs_subscribers_id_seq; Type: SEQUENCE; Schema: public; Owner: agentyk
--

ALTER TABLE public.subs_subscribers ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.subs_subscribers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: subscriber_invoices; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.subscriber_invoices (
    invoice_id text NOT NULL,
    subscriber_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.subscriber_invoices OWNER TO agentyk;

--
-- Name: translations; Type: VIEW; Schema: public; Owner: agentyk
--

CREATE VIEW public.translations AS
 WITH RECURSIVE translations_with_paths AS (
         SELECT d.dict_id,
            t.sentence,
            t.translation,
            ARRAY[d.dict_id] AS path
           FROM (public.lang_translations t
             JOIN public.lang_dictionaries d USING (dict_id))
        UNION ALL
         SELECT d.dict_id,
            t.sentence,
            t.translation,
            (d.dict_id || t.path)
           FROM (translations_with_paths t
             JOIN public.lang_dictionaries d ON ((d.fallback = t.dict_id)))
        ), ranked_translations AS (
         SELECT translations_with_paths.dict_id,
            translations_with_paths.sentence,
            translations_with_paths.translation,
            translations_with_paths.path,
            row_number() OVER (PARTITION BY translations_with_paths.dict_id, translations_with_paths.sentence ORDER BY (array_length(translations_with_paths.path, 1))) AS rn
           FROM translations_with_paths
        )
 SELECT dict_id,
    sentence,
    translation,
    path
   FROM ranked_translations
  WHERE (rn = 1);


ALTER VIEW public.translations OWNER TO agentyk;

--
-- Name: VIEW translations; Type: COMMENT; Schema: public; Owner: agentyk
--

COMMENT ON VIEW public.translations IS 'Compute the translation for all sentences for all dictionaries, taking into account fallbacks';


--
-- Name: InvoiceSearches Id; Type: DEFAULT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."InvoiceSearches" ALTER COLUMN "Id" SET DEFAULT nextval('public."InvoiceSearches_Id_seq"'::regclass);


--
-- Data for Name: AddressInvoices; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."AddressInvoices" ("Address", "InvoiceDataId", "PaymentMethodId") FROM stdin;
\.


--
-- Data for Name: ApiKeys; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."ApiKeys" ("Id", "StoreId", "Type", "UserId", "Label", "Blob", "Blob2") FROM stdin;
ced28e026a7c85829f21355066dd7d428ed119c6	\N	1	38b72400-0861-46e2-a052-5f735f7cfda5	agentyk-backend	\\x	{"permissions": ["btcpay.server.canmodifyserversettings", "btcpay.store.canmodifystoresettings", "btcpay.store.cancreateinvoice", "btcpay.store.canviewinvoices", "btcpay.store.canmodifyinvoices", "btcpay.store.canviewstoresettings", "btcpay.store.canmanagepullpayments"], "applicationAuthority": null, "applicationIdentifier": null}
\.


--
-- Data for Name: Apps; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."Apps" ("Id", "AppType", "Created", "Name", "Settings", "StoreDataId", "TagAllInvoices", "Archived") FROM stdin;
\.


--
-- Data for Name: AspNetRoleClaims; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."AspNetRoleClaims" ("Id", "ClaimType", "ClaimValue", "RoleId") FROM stdin;
\.


--
-- Data for Name: AspNetRoles; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."AspNetRoles" ("Id", "ConcurrencyStamp", "Name", "NormalizedName") FROM stdin;
405f077d-b107-47cf-8137-c6c4c3e1a008	\N	ServerAdmin	SERVERADMIN
\.


--
-- Data for Name: AspNetUserClaims; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."AspNetUserClaims" ("Id", "ClaimType", "ClaimValue", "UserId") FROM stdin;
\.


--
-- Data for Name: AspNetUserLogins; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."AspNetUserLogins" ("LoginProvider", "ProviderKey", "ProviderDisplayName", "UserId") FROM stdin;
\.


--
-- Data for Name: AspNetUserRoles; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."AspNetUserRoles" ("UserId", "RoleId") FROM stdin;
38b72400-0861-46e2-a052-5f735f7cfda5	405f077d-b107-47cf-8137-c6c4c3e1a008
\.


--
-- Data for Name: AspNetUserTokens; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."AspNetUserTokens" ("UserId", "LoginProvider", "Name", "Value") FROM stdin;
\.


--
-- Data for Name: AspNetUsers; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."AspNetUsers" ("Id", "AccessFailedCount", "ConcurrencyStamp", "Email", "EmailConfirmed", "LockoutEnabled", "LockoutEnd", "NormalizedEmail", "NormalizedUserName", "PasswordHash", "PhoneNumber", "PhoneNumberConfirmed", "SecurityStamp", "TwoFactorEnabled", "UserName", "RequiresEmailConfirmation", "Created", "DisabledNotifications", "Blob", "Blob2", "Approved", "RequiresApproval") FROM stdin;
38b72400-0861-46e2-a052-5f735f7cfda5	0	3f637771-64a5-4dec-8495-3c73f99d5cc0	admin@agentyk.ru	f	t	\N	ADMIN@AGENTYK.RU	ADMIN@AGENTYK.RU	AQAAAAIAAYagAAAAED/coZadg6xIl/1YCvb7cPZnKUN7DVqlm5YHNg1H1635Mb0HihavQC0a+cDMkJDrRQ==	\N	f	WCEGUXDXBUEVDB7V3EMGLHL5YLQXHEEI	f	admin@agentyk.ru	f	2026-03-07 18:51:08.151602+00	\N	\\x	{"name": null, "imageUrl": null, "invitationToken": null, "showInvoiceStatusChangeHint": false}	t	f
\.


--
-- Data for Name: Fido2Credentials; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."Fido2Credentials" ("Id", "Name", "ApplicationUserId", "Blob", "Type", "Blob2") FROM stdin;
\.


--
-- Data for Name: Files; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."Files" ("Id", "FileName", "StorageFileName", "Timestamp", "ApplicationUserId") FROM stdin;
\.


--
-- Data for Name: Forms; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."Forms" ("Id", "Name", "StoreId", "Config", "Public") FROM stdin;
\.


--
-- Data for Name: InvoiceEvents; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."InvoiceEvents" ("InvoiceDataId", "Message", "Timestamp", "Severity") FROM stdin;
\.


--
-- Data for Name: InvoiceSearches; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."InvoiceSearches" ("Id", "InvoiceDataId", "Value") FROM stdin;
\.


--
-- Data for Name: InvoiceWebhookDeliveries; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."InvoiceWebhookDeliveries" ("InvoiceId", "DeliveryId") FROM stdin;
\.


--
-- Data for Name: Invoices; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."Invoices" ("Id", "Blob", "Created", "ExceptionStatus", "Status", "StoreDataId", "Archived", "Blob2", "Amount", "Currency") FROM stdin;
\.


--
-- Data for Name: LightningAddresses; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."LightningAddresses" ("Username", "StoreDataId", "Blob", "Blob2") FROM stdin;
\.


--
-- Data for Name: Notifications; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."Notifications" ("Id", "Created", "ApplicationUserId", "NotificationType", "Seen", "Blob", "Blob2") FROM stdin;
\.


--
-- Data for Name: OffchainTransactions; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."OffchainTransactions" ("Id", "Blob") FROM stdin;
\.


--
-- Data for Name: PairedSINData; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."PairedSINData" ("Id", "Label", "PairingTime", "SIN", "StoreDataId") FROM stdin;
\.


--
-- Data for Name: PairingCodes; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."PairingCodes" ("Id", "DateCreated", "Expiration", "Facade", "Label", "SIN", "StoreDataId", "TokenValue") FROM stdin;
\.


--
-- Data for Name: PayjoinLocks; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."PayjoinLocks" ("Id") FROM stdin;
\.


--
-- Data for Name: PaymentRequests; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."PaymentRequests" ("Id", "StoreDataId", "Blob", "Created", "Archived", "Blob2", "ReferenceId", "Expiry", "Amount", "Currency", "Status", "Title") FROM stdin;
\.


--
-- Data for Name: Payments; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."Payments" ("Id", "Blob", "InvoiceDataId", "Accounted", "Blob2", "PaymentMethodId", "Amount", "Created", "Currency", "Status") FROM stdin;
\.


--
-- Data for Name: PayoutProcessors; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."PayoutProcessors" ("Id", "StoreId", "PayoutMethodId", "Processor", "Blob", "Blob2") FROM stdin;
\.


--
-- Data for Name: Payouts; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."Payouts" ("Id", "Date", "PullPaymentDataId", "State", "PayoutMethodId", "DedupId", "Blob", "Proof", "StoreDataId", "Currency", "Amount", "OriginalAmount", "OriginalCurrency") FROM stdin;
\.


--
-- Data for Name: PendingTransactions; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."PendingTransactions" ("TransactionId", "CryptoCode", "StoreId", "Expiry", "State", "OutpointsUsed", "Blob2", "Id") FROM stdin;
\.


--
-- Data for Name: PlannedTransactions; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."PlannedTransactions" ("Id", "BroadcastAt", "Blob") FROM stdin;
\.


--
-- Data for Name: PullPayments; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."PullPayments" ("Id", "StoreId", "StartDate", "EndDate", "Archived", "Blob", "Currency", "Limit") FROM stdin;
\.


--
-- Data for Name: Refunds; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."Refunds" ("InvoiceDataId", "PullPaymentDataId") FROM stdin;
\.


--
-- Data for Name: Settings; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."Settings" ("Id", "Value") FROM stdin;
BTCPayServer.Storage.Models.StorageSettings	{"Provider": 3, "ConfigurationStr": "{\\n  \\"ContainerName\\": \\"\\"\\n}"}
BTCPayServer.Services.MigrationSettings	{"AddStoreToPayout": true, "MigrateU2FToFIDO2": true, "AddInitialUserBlob": true, "MigrateAppYmlToJson": true, "MigrateWalletColors": true, "MigrateToStoreConfig": true, "PaymentMethodCriteria": true, "FixMappedDomainAppType": true, "MigrateAppCustomOption": true, "MigrateBlockExplorerLinks": true, "MigrateHotwalletProperty2": true, "MigratedTransactionLabels": 2147483647, "FileSystemStorageAsDefault": true, "MigratePayoutDestinationId": true, "LighingAddressSettingRename": true, "MigrateOldDerivationSchemes": true, "MigratedInvoiceTextSearchPages": 2147483647, "LighingAddressDatabaseMigration": true, "MigrateEmailServerDisableTLSCerts": true, "MigrateStoreExcludedPaymentMethods": true, "TransitionToStoreBlobAdditionalData": true, "TransitionInternalNodeConnectionString": true}
PaymentRequestsMigration3	{"Complete": true, "Progress": null}
InvoicesMigration	{"Complete": true, "Progress": null}
BTCPayServer.Services.ThemeSettings	{"LogoUrl": null, "FirstRun": false, "CustomTheme": false, "CustomThemeCssUrl": null, "CustomThemeExtension": 0}
BTCPayServer.Services.PoliciesSettings	{"RootAppId": null, "DefaultRole": null, "RootAppType": null, "Experimental": false, "PluginSource": null, "LangDictionary": "English", "LockSubscription": true, "DisableSSHService": false, "PluginPreReleases": false, "BlockExplorerLinks": [], "DomainToAppMapping": [], "CheckForNewVersions": false, "AllowHotWalletForAll": false, "DefaultStoreTemplate": null, "RegisterPageRedirect": null, "RequiresUserApproval": false, "RequiresConfirmedEmail": false, "DiscourageSearchEngines": false, "AllowCreateColdWalletForAll": false, "DisableNonAdminCreateUserApi": false, "AllowHotWalletRPCImportForAll": false, "AllowLightningInternalNodeForAll": false, "DisableStoresToUseServerEmailSettings": false}
BTCPayServer.HostedServices.PluginVersionCheckerDataHolder	{"LastVersions": {}}
\.


--
-- Data for Name: StoreRoles; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."StoreRoles" ("Id", "StoreDataId", "Role", "Permissions") FROM stdin;
Manager	\N	Manager	{btcpay.store.canviewstoresettings,btcpay.store.canmodifyinvoices,btcpay.store.webhooks.canmodifywebhooks,btcpay.store.canmodifypaymentrequests,btcpay.store.canmanagepullpayments,btcpay.store.canmanagepayouts}
Employee	\N	Employee	{btcpay.store.canmodifyinvoices,btcpay.store.canmodifypaymentrequests,btcpay.store.cancreatenonapprovedpullpayments,btcpay.store.canviewpayouts,btcpay.store.canviewpullpayments}
Guest	\N	Guest	{btcpay.store.canmodifyinvoices,btcpay.store.canviewpaymentrequests,btcpay.store.canviewpullpayments,btcpay.store.canviewpayouts}
Owner	\N	Owner	{btcpay.store.canmodifystoresettings}
\.


--
-- Data for Name: StoreSettings; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."StoreSettings" ("Name", "StoreId", "Value") FROM stdin;
\.


--
-- Data for Name: StoreWebhooks; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."StoreWebhooks" ("StoreId", "WebhookId") FROM stdin;
\.


--
-- Data for Name: Stores; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."Stores" ("Id", "DerivationStrategy", "SpeedPolicy", "StoreCertificate", "StoreName", "StoreWebsite", "StoreBlob", "DerivationStrategies", "DefaultCrypto", "Archived") FROM stdin;
8qwjQiiHac6abEMNikodQPVL9h4RbTtTGfTZM8paJzZv	\N	1	\N	AgentYK	\N	{"cssUrl": null, "spread": 0.0, "logoUrl": null, "htmlTitle": null, "brandColor": null, "defaultLang": null, "checkoutText": null, "noActiveUser": false, "emailSettings": null, "networkFeeMode": "MultiplePaymentsOnly", "payJoinEnabled": false, "receiptOptions": {"showQR": true, "enabled": true, "showPayments": true}, "defaultCurrency": "USD", "paymentSoundUrl": null, "showStoreHeader": true, "storeSupportUrl": null, "anyoneCanInvoice": false, "celebratePayment": true, "paymentTolerance": 0.0, "invoiceExpiration": 15, "autoDetectLanguage": false, "lazyPaymentMethods": false, "playSoundOnPayment": false, "showRecommendedFee": true, "primaryRateSettings": null, "defaultCurrencyPairs": [], "fallbackRateSettings": null, "monitoringExpiration": 1440, "paymentMethodCriteria": [], "redirectAutomatically": false, "showPayInWalletButton": true, "additionalTrackedRates": [], "displayExpirationTimer": 5, "excludedPaymentMethods": [], "applyBrandColorToBackend": false, "lightningAmountInSatoshi": false, "recommendedFeeBlockTarget": 1, "lightningPrivateRouteHints": false, "lightningDescriptionTemplate": "Paid to {StoreName} (Order ID: {OrderId})", "onChainWithLnInvoiceFallback": false}	\N	\N	f
\.


--
-- Data for Name: U2FDevices; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."U2FDevices" ("Id", "Name", "KeyHandle", "PublicKey", "AttestationCert", "Counter", "ApplicationUserId") FROM stdin;
\.


--
-- Data for Name: UserStore; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."UserStore" ("ApplicationUserId", "StoreDataId", "Role") FROM stdin;
38b72400-0861-46e2-a052-5f735f7cfda5	8qwjQiiHac6abEMNikodQPVL9h4RbTtTGfTZM8paJzZv	Owner
\.


--
-- Data for Name: WalletObjectLinks; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."WalletObjectLinks" ("WalletId", "AType", "AId", "BType", "BId", "Data") FROM stdin;
\.


--
-- Data for Name: WalletObjects; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."WalletObjects" ("WalletId", "Type", "Id", "Data") FROM stdin;
\.


--
-- Data for Name: WalletTransactions; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."WalletTransactions" ("WalletDataId", "TransactionId", "Labels", "Blob") FROM stdin;
\.


--
-- Data for Name: Wallets; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."Wallets" ("Id", "Blob") FROM stdin;
\.


--
-- Data for Name: WebhookDeliveries; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."WebhookDeliveries" ("Id", "WebhookId", "Timestamp", "Pruned", "Blob", "DeliveryTime") FROM stdin;
\.


--
-- Data for Name: Webhooks; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."Webhooks" ("Id", "Blob", "Blob2") FROM stdin;
\.


--
-- Data for Name: __EFMigrationsHistory; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public."__EFMigrationsHistory" ("MigrationId", "ProductVersion") FROM stdin;
20200225133433_AddApiKeyLabel	8.0.11
20200402065615_AddApiKeyBlob	8.0.11
20200413052418_PlannedTransactions	8.0.11
20200507092343_AddArchivedToInvoice	8.0.11
20200625064111_refundnotificationpullpayments	8.0.11
20200901161733_AddInvoiceEventLogSeverity	8.0.11
20201002145033_AddCreateDateToUser	8.0.11
20201007090617_u2fDeviceCascade	8.0.11
20201015151438_AddDisabledNotificationsToUser	8.0.11
20201108054749_webhooks	8.0.11
20201208054211_invoicesorderindex	8.0.11
20201228225040_AddingInvoiceSearchesTable	8.0.11
20210314092253_Fido2Credentials	8.0.11
20211021085011_RemovePayoutDestinationConstraint	8.0.11
20211125081400_AddUserBlob	8.0.11
20220115184620_AddCustodianAccountData	8.0.11
20220311135252_AddPayoutProcessors	8.0.11
20220414132313_AddLightningAddress	8.0.11
20220518061525_invoice_created_idx	8.0.11
20220523022603_remove_historical_addresses	8.0.11
20220610090843_AddSettingsToStore	8.0.11
20220929132704_label	8.0.11
20221128062447_jsonb	8.0.11
20230123062447_migrateoldratesource	8.0.11
20230125085242_AddForms	8.0.11
20230130040047_blob2	8.0.11
20230130062447_jsonb2	8.0.11
20230315062447_fixmaxlength	8.0.11
20230504125505_StoreRoles	8.0.11
20230529135505_WebhookDeliveriesCleanup	8.0.11
20230906135844_AddArchivedFlagForStoresAndApps	8.0.11
20231020135844_AddBoltcardsTable	8.0.11
20231121031609_removecurrentrefund	8.0.11
20231219031609_appssettingstojson	8.0.11
20231219031609_translationsmigration	8.0.11
20240104155620_AddApprovalToApplicationUser	8.0.11
20240220000000_FixWalletObjectsWithEmptyWalletId	8.0.11
20240229000000_PayoutAndPullPaymentToJsonBlob	8.0.11
20240229092905_AddManagerAndEmployeeToStoreRoles	8.0.11
20240304003640_addinvoicecolumns	8.0.11
20240317024757_payments_refactor	8.0.11
20240325095923_RemoveCustodian	8.0.11
20240405004015_cleanup_invoice_events	8.0.11
20240501015052_noperiod	8.0.11
20240508015052_fileid	8.0.11
20240826065950_removeinvoicecols	8.0.11
20240827034505_migratepayouts	8.0.11
20240904092905_UpdateStoreOwnerRole	8.0.11
20240913034505_refactorpendinginvoicespayments	8.0.11
20240919085726_refactorinvoiceaddress	8.0.11
20240923065254_refactorpayments	8.0.11
20240924065254_monitoredinvoices	8.0.11
20241029163147_AddingPendingTransactionsTable	8.0.11
20250407133937_AddingReferenceIdToPaymentRequest	8.0.11
20250407133937_pr_expiry	8.0.11
20250418074941_changependingtxsid	8.0.11
20250501000000_storetemplate	8.0.11
20250508000000_fallbackrates	8.0.11
20250709000000_lightningaddressinmetadata	8.0.11
20251015142818_emailrules	8.0.11
20251028061727_subs	8.0.11
20251107131717_emailccbcc	8.0.11
20251216120000_pr_title	8.0.11
20251231034124_subs_payment_reminder	8.0.11
20260112034124_disable_orphan_stores	8.0.11
20260112034125_replace_coingecko	8.0.11
20260114053517_StoreScopedLabels	8.0.11
20260126093615_wh_delivery_time	8.0.11
20251109_defaultserverrules	8.0.11
20251223_emailsettingsmigration	8.0.11
20260106_cleanupappidentities	8.0.11
\.


--
-- Data for Name: boltcards; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.boltcards (id, counter, ppid, version) FROM stdin;
\.


--
-- Data for Name: customers; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.customers (id, store_id, external_ref, name, metadata, additional_data, created_at) FROM stdin;
\.


--
-- Data for Name: customers_identities; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.customers_identities (customer_id, type, value) FROM stdin;
\.


--
-- Data for Name: email_rules; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.email_rules ("Id", store_id, trigger, condition, "to", subject, body, metadata, additional_data, created_at, offering_id, bcc, cc) FROM stdin;
1	\N	SRV-PasswordReset	\N	{"{User.MailboxAddress}"}	Update Password	<html><body style='font-family: Open Sans, Helvetica Neue,Arial,sans-serif; font-color: #292929;'><h1 style='font-size:1.2rem'>{Server.Name}</h1><br/>A request has been made to reset your {Server.Name} password. Please set your password by clicking below.<br/><br/><a href='{ResetLink}' type='submit' style='min-width: 2em;min-height: 20px;text-decoration-line: none;cursor: pointer;display: inline-block;font-weight: 400;color: #fff;text-align: center;vertical-align: middle;user-select: none;background-color: #51b13e;border-color: #51b13e;border: 1px solid transparent;padding: 0.375rem 0.75rem;font-size: 1rem;line-height: 1.5;border-radius: 0.25rem;transition: color 0.15s ease-in-out, background-color 0.15s ease-in-out, border-color 0.15s ease-in-out, box-shadow 0.15s ease-in-out;'>Update Password</a></body></html>	{}	{}	2026-03-07 18:45:59.040737+00	\N	{}	{}
2	\N	SRV-EmailConfirmation	\N	{"{User.MailboxAddress}"}	Confirm your email address	<html><body style='font-family: Open Sans, Helvetica Neue,Arial,sans-serif; font-color: #292929;'><h1 style='font-size:1.2rem'>{Server.Name}</h1><br/>Please confirm your account.<br/><br/><a href='{ConfirmLink}' type='submit' style='min-width: 2em;min-height: 20px;text-decoration-line: none;cursor: pointer;display: inline-block;font-weight: 400;color: #fff;text-align: center;vertical-align: middle;user-select: none;background-color: #51b13e;border-color: #51b13e;border: 1px solid transparent;padding: 0.375rem 0.75rem;font-size: 1rem;line-height: 1.5;border-radius: 0.25rem;transition: color 0.15s ease-in-out, background-color 0.15s ease-in-out, border-color 0.15s ease-in-out, box-shadow 0.15s ease-in-out;'>Confirm Email</a></body></html>	{}	{}	2026-03-07 18:45:59.079154+00	\N	{}	{}
3	\N	SRV-InvitePending	\N	{"{User.MailboxAddress}"}	Invitation to join {Server.Name}	<html><body style='font-family: Open Sans, Helvetica Neue,Arial,sans-serif; font-color: #292929;'><h1 style='font-size:1.2rem'>{Server.Name}</h1><br/><p>Please complete your account setup by clicking <a href='{InvitationLink}'>this link</a>.</p><p>You can also use the BTCPay Server app and scan this QR code when connecting:</p>{InvitationLinkQR}</body></html>	{}	{}	2026-03-07 18:45:59.079707+00	\N	{}	{}
4	\N	SRV-ApprovalConfirmed	\N	{"{User.MailboxAddress}"}	Your account has been approved	<html><body style='font-family: Open Sans, Helvetica Neue,Arial,sans-serif; font-color: #292929;'><h1 style='font-size:1.2rem'>{Server.Name}</h1><br/>Your account has been approved and you can now log in.<br/><br/><a href='{LoginLink}' type='submit' style='min-width: 2em;min-height: 20px;text-decoration-line: none;cursor: pointer;display: inline-block;font-weight: 400;color: #fff;text-align: center;vertical-align: middle;user-select: none;background-color: #51b13e;border-color: #51b13e;border: 1px solid transparent;padding: 0.375rem 0.75rem;font-size: 1rem;line-height: 1.5;border-radius: 0.25rem;transition: color 0.15s ease-in-out, background-color 0.15s ease-in-out, border-color 0.15s ease-in-out, box-shadow 0.15s ease-in-out;'>Login here</a></body></html>	{}	{}	2026-03-07 18:45:59.079748+00	\N	{}	{}
5	\N	SRV-ApprovalRequest	\N	{"{Admins.MailboxAddresses}"}	Approval request to access the server for {User.Email}	<html><body style='font-family: Open Sans, Helvetica Neue,Arial,sans-serif; font-color: #292929;'><h1 style='font-size:1.2rem'>{Server.Name}</h1><br/>A new user ({User.MailboxAddress}), is awaiting approval to access the server.<br/><br/><a href='{ApprovalLink}' type='submit' style='min-width: 2em;min-height: 20px;text-decoration-line: none;cursor: pointer;display: inline-block;font-weight: 400;color: #fff;text-align: center;vertical-align: middle;user-select: none;background-color: #51b13e;border-color: #51b13e;border: 1px solid transparent;padding: 0.375rem 0.75rem;font-size: 1rem;line-height: 1.5;border-radius: 0.25rem;transition: color 0.15s ease-in-out, background-color 0.15s ease-in-out, border-color 0.15s ease-in-out, box-shadow 0.15s ease-in-out;'>Approve</a></body></html>	{}	{}	2026-03-07 18:45:59.079783+00	\N	{}	{}
\.


--
-- Data for Name: lang_dictionaries; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.lang_dictionaries (dict_id, fallback, source, metadata) FROM stdin;
English	\N	Default	\N
\.


--
-- Data for Name: lang_translations; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.lang_translations (dict_id, sentence, translation) FROM stdin;
\.


--
-- Data for Name: store_label_links; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.store_label_links (store_id, store_label_id, object_id) FROM stdin;
\.


--
-- Data for Name: store_labels; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.store_labels (store_id, id, type, text, color) FROM stdin;
\.


--
-- Data for Name: subs_features; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.subs_features (id, custom_id, offering_id, description) FROM stdin;
\.


--
-- Data for Name: subs_offerings; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.subs_offerings (id, app_id, success_redirect_url, payment_reminder_days, metadata, additional_data, created_at) FROM stdin;
\.


--
-- Data for Name: subs_plan_changes; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.subs_plan_changes (plan_id, plan_change_id, type) FROM stdin;
\.


--
-- Data for Name: subs_plan_checkouts; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.subs_plan_checkouts (id, invoice_id, success_redirect_url, is_trial, plan_id, new_subscriber, new_subscriber_email, subscriber_id, invoice_metadata, new_subscriber_metadata, test_account, credited, plan_started, credit_purchase, refund_amount, on_pay, base_url, expiration, metadata, additional_data, created_at) FROM stdin;
\.


--
-- Data for Name: subs_plans; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.subs_plans (id, offering_id, name, status, price, currency, recurring_type, grace_period_days, trial_days, description, members_count, monthly_revenue, optimistic_activation, renewable, metadata, additional_data, created_at) FROM stdin;
\.


--
-- Data for Name: subs_plans_features; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.subs_plans_features (plan_id, feature_id) FROM stdin;
\.


--
-- Data for Name: subs_portal_sessions; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.subs_portal_sessions (id, subscriber_id, expiration, base_url) FROM stdin;
\.


--
-- Data for Name: subs_subscriber_credits; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.subs_subscriber_credits (subscriber_id, currency, amount) FROM stdin;
\.


--
-- Data for Name: subs_subscriber_credits_history; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.subs_subscriber_credits_history ("Id", subscriber_id, currency, created_at, description, debit, credit, balance) FROM stdin;
\.


--
-- Data for Name: subs_subscribers; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.subs_subscribers (id, offering_id, customer_id, plan_id, new_plan_id, paid_amount, processing_invoice_id, phase, plan_started, period_end, optimistic_activation, trial_end, grace_period_end, auto_renew, active, payment_reminder_days, payment_reminded, suspended, test_account, suspension_reason, metadata, additional_data, created_at, reminder_date) FROM stdin;
\.


--
-- Data for Name: subscriber_invoices; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.subscriber_invoices (invoice_id, subscriber_id, created_at) FROM stdin;
\.


--
-- Name: InvoiceSearches_Id_seq; Type: SEQUENCE SET; Schema: public; Owner: agentyk
--

SELECT pg_catalog.setval('public."InvoiceSearches_Id_seq"', 1, false);


--
-- Name: email_rules_Id_seq; Type: SEQUENCE SET; Schema: public; Owner: agentyk
--

SELECT pg_catalog.setval('public."email_rules_Id_seq"', 5, true);


--
-- Name: subs_features_id_seq; Type: SEQUENCE SET; Schema: public; Owner: agentyk
--

SELECT pg_catalog.setval('public.subs_features_id_seq', 1, false);


--
-- Name: subs_subscriber_credits_history_Id_seq; Type: SEQUENCE SET; Schema: public; Owner: agentyk
--

SELECT pg_catalog.setval('public."subs_subscriber_credits_history_Id_seq"', 1, false);


--
-- Name: subs_subscribers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: agentyk
--

SELECT pg_catalog.setval('public.subs_subscribers_id_seq', 1, false);


--
-- Name: AddressInvoices PK_AddressInvoices; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."AddressInvoices"
    ADD CONSTRAINT "PK_AddressInvoices" PRIMARY KEY ("Address", "PaymentMethodId");


--
-- Name: ApiKeys PK_ApiKeys; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."ApiKeys"
    ADD CONSTRAINT "PK_ApiKeys" PRIMARY KEY ("Id");


--
-- Name: Apps PK_Apps; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."Apps"
    ADD CONSTRAINT "PK_Apps" PRIMARY KEY ("Id");


--
-- Name: AspNetRoleClaims PK_AspNetRoleClaims; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."AspNetRoleClaims"
    ADD CONSTRAINT "PK_AspNetRoleClaims" PRIMARY KEY ("Id");


--
-- Name: AspNetRoles PK_AspNetRoles; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."AspNetRoles"
    ADD CONSTRAINT "PK_AspNetRoles" PRIMARY KEY ("Id");


--
-- Name: AspNetUserClaims PK_AspNetUserClaims; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."AspNetUserClaims"
    ADD CONSTRAINT "PK_AspNetUserClaims" PRIMARY KEY ("Id");


--
-- Name: AspNetUserLogins PK_AspNetUserLogins; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."AspNetUserLogins"
    ADD CONSTRAINT "PK_AspNetUserLogins" PRIMARY KEY ("LoginProvider", "ProviderKey");


--
-- Name: AspNetUserRoles PK_AspNetUserRoles; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."AspNetUserRoles"
    ADD CONSTRAINT "PK_AspNetUserRoles" PRIMARY KEY ("UserId", "RoleId");


--
-- Name: AspNetUserTokens PK_AspNetUserTokens; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."AspNetUserTokens"
    ADD CONSTRAINT "PK_AspNetUserTokens" PRIMARY KEY ("UserId", "LoginProvider", "Name");


--
-- Name: AspNetUsers PK_AspNetUsers; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."AspNetUsers"
    ADD CONSTRAINT "PK_AspNetUsers" PRIMARY KEY ("Id");


--
-- Name: Fido2Credentials PK_Fido2Credentials; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."Fido2Credentials"
    ADD CONSTRAINT "PK_Fido2Credentials" PRIMARY KEY ("Id");


--
-- Name: Files PK_Files; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."Files"
    ADD CONSTRAINT "PK_Files" PRIMARY KEY ("Id");


--
-- Name: Forms PK_Forms; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."Forms"
    ADD CONSTRAINT "PK_Forms" PRIMARY KEY ("Id");


--
-- Name: InvoiceSearches PK_InvoiceSearches; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."InvoiceSearches"
    ADD CONSTRAINT "PK_InvoiceSearches" PRIMARY KEY ("Id");


--
-- Name: InvoiceWebhookDeliveries PK_InvoiceWebhookDeliveries; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."InvoiceWebhookDeliveries"
    ADD CONSTRAINT "PK_InvoiceWebhookDeliveries" PRIMARY KEY ("InvoiceId", "DeliveryId");


--
-- Name: Invoices PK_Invoices; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."Invoices"
    ADD CONSTRAINT "PK_Invoices" PRIMARY KEY ("Id");


--
-- Name: LightningAddresses PK_LightningAddresses; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."LightningAddresses"
    ADD CONSTRAINT "PK_LightningAddresses" PRIMARY KEY ("Username");


--
-- Name: Notifications PK_Notifications; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."Notifications"
    ADD CONSTRAINT "PK_Notifications" PRIMARY KEY ("Id");


--
-- Name: OffchainTransactions PK_OffchainTransactions; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."OffchainTransactions"
    ADD CONSTRAINT "PK_OffchainTransactions" PRIMARY KEY ("Id");


--
-- Name: PairedSINData PK_PairedSINData; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."PairedSINData"
    ADD CONSTRAINT "PK_PairedSINData" PRIMARY KEY ("Id");


--
-- Name: PairingCodes PK_PairingCodes; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."PairingCodes"
    ADD CONSTRAINT "PK_PairingCodes" PRIMARY KEY ("Id");


--
-- Name: PayjoinLocks PK_PayjoinLocks; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."PayjoinLocks"
    ADD CONSTRAINT "PK_PayjoinLocks" PRIMARY KEY ("Id");


--
-- Name: PaymentRequests PK_PaymentRequests; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."PaymentRequests"
    ADD CONSTRAINT "PK_PaymentRequests" PRIMARY KEY ("Id");


--
-- Name: Payments PK_Payments; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."Payments"
    ADD CONSTRAINT "PK_Payments" PRIMARY KEY ("Id", "PaymentMethodId");


--
-- Name: PayoutProcessors PK_PayoutProcessors; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."PayoutProcessors"
    ADD CONSTRAINT "PK_PayoutProcessors" PRIMARY KEY ("Id");


--
-- Name: Payouts PK_Payouts; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."Payouts"
    ADD CONSTRAINT "PK_Payouts" PRIMARY KEY ("Id");


--
-- Name: PendingTransactions PK_PendingTransactions; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."PendingTransactions"
    ADD CONSTRAINT "PK_PendingTransactions" PRIMARY KEY ("Id");


--
-- Name: PlannedTransactions PK_PlannedTransactions; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."PlannedTransactions"
    ADD CONSTRAINT "PK_PlannedTransactions" PRIMARY KEY ("Id");


--
-- Name: PullPayments PK_PullPayments; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."PullPayments"
    ADD CONSTRAINT "PK_PullPayments" PRIMARY KEY ("Id");


--
-- Name: Refunds PK_Refunds; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."Refunds"
    ADD CONSTRAINT "PK_Refunds" PRIMARY KEY ("InvoiceDataId", "PullPaymentDataId");


--
-- Name: Settings PK_Settings; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."Settings"
    ADD CONSTRAINT "PK_Settings" PRIMARY KEY ("Id");


--
-- Name: StoreRoles PK_StoreRoles; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."StoreRoles"
    ADD CONSTRAINT "PK_StoreRoles" PRIMARY KEY ("Id");


--
-- Name: StoreSettings PK_StoreSettings; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."StoreSettings"
    ADD CONSTRAINT "PK_StoreSettings" PRIMARY KEY ("StoreId", "Name");


--
-- Name: StoreWebhooks PK_StoreWebhooks; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."StoreWebhooks"
    ADD CONSTRAINT "PK_StoreWebhooks" PRIMARY KEY ("StoreId", "WebhookId");


--
-- Name: Stores PK_Stores; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."Stores"
    ADD CONSTRAINT "PK_Stores" PRIMARY KEY ("Id");


--
-- Name: U2FDevices PK_U2FDevices; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."U2FDevices"
    ADD CONSTRAINT "PK_U2FDevices" PRIMARY KEY ("Id");


--
-- Name: UserStore PK_UserStore; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."UserStore"
    ADD CONSTRAINT "PK_UserStore" PRIMARY KEY ("ApplicationUserId", "StoreDataId");


--
-- Name: WalletObjectLinks PK_WalletObjectLinks; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."WalletObjectLinks"
    ADD CONSTRAINT "PK_WalletObjectLinks" PRIMARY KEY ("WalletId", "AType", "AId", "BType", "BId");


--
-- Name: WalletObjects PK_WalletObjects; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."WalletObjects"
    ADD CONSTRAINT "PK_WalletObjects" PRIMARY KEY ("WalletId", "Type", "Id");


--
-- Name: WalletTransactions PK_WalletTransactions; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."WalletTransactions"
    ADD CONSTRAINT "PK_WalletTransactions" PRIMARY KEY ("WalletDataId", "TransactionId");


--
-- Name: Wallets PK_Wallets; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."Wallets"
    ADD CONSTRAINT "PK_Wallets" PRIMARY KEY ("Id");


--
-- Name: WebhookDeliveries PK_WebhookDeliveries; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."WebhookDeliveries"
    ADD CONSTRAINT "PK_WebhookDeliveries" PRIMARY KEY ("Id");


--
-- Name: Webhooks PK_Webhooks; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."Webhooks"
    ADD CONSTRAINT "PK_Webhooks" PRIMARY KEY ("Id");


--
-- Name: __EFMigrationsHistory PK___EFMigrationsHistory; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."__EFMigrationsHistory"
    ADD CONSTRAINT "PK___EFMigrationsHistory" PRIMARY KEY ("MigrationId");


--
-- Name: customers PK_customers; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT "PK_customers" PRIMARY KEY (id);


--
-- Name: customers_identities PK_customers_identities; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.customers_identities
    ADD CONSTRAINT "PK_customers_identities" PRIMARY KEY (customer_id, type);


--
-- Name: email_rules PK_email_rules; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.email_rules
    ADD CONSTRAINT "PK_email_rules" PRIMARY KEY ("Id");


--
-- Name: boltcards PK_id; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.boltcards
    ADD CONSTRAINT "PK_id" PRIMARY KEY (id);


--
-- Name: store_label_links PK_store_label_links; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.store_label_links
    ADD CONSTRAINT "PK_store_label_links" PRIMARY KEY (store_id, store_label_id, object_id);


--
-- Name: store_labels PK_store_labels; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.store_labels
    ADD CONSTRAINT "PK_store_labels" PRIMARY KEY (store_id, id);


--
-- Name: subs_features PK_subs_features; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.subs_features
    ADD CONSTRAINT "PK_subs_features" PRIMARY KEY (id);


--
-- Name: subs_offerings PK_subs_offerings; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.subs_offerings
    ADD CONSTRAINT "PK_subs_offerings" PRIMARY KEY (id);


--
-- Name: subs_plan_changes PK_subs_plan_changes; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.subs_plan_changes
    ADD CONSTRAINT "PK_subs_plan_changes" PRIMARY KEY (plan_id, plan_change_id);


--
-- Name: subs_plan_checkouts PK_subs_plan_checkouts; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.subs_plan_checkouts
    ADD CONSTRAINT "PK_subs_plan_checkouts" PRIMARY KEY (id);


--
-- Name: subs_plans PK_subs_plans; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.subs_plans
    ADD CONSTRAINT "PK_subs_plans" PRIMARY KEY (id);


--
-- Name: subs_plans_features PK_subs_plans_features; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.subs_plans_features
    ADD CONSTRAINT "PK_subs_plans_features" PRIMARY KEY (plan_id, feature_id);


--
-- Name: subs_portal_sessions PK_subs_portal_sessions; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.subs_portal_sessions
    ADD CONSTRAINT "PK_subs_portal_sessions" PRIMARY KEY (id);


--
-- Name: subs_subscriber_credits PK_subs_subscriber_credits; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.subs_subscriber_credits
    ADD CONSTRAINT "PK_subs_subscriber_credits" PRIMARY KEY (subscriber_id, currency);


--
-- Name: subs_subscriber_credits_history PK_subs_subscriber_credits_history; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.subs_subscriber_credits_history
    ADD CONSTRAINT "PK_subs_subscriber_credits_history" PRIMARY KEY ("Id");


--
-- Name: subs_subscribers PK_subs_subscribers; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.subs_subscribers
    ADD CONSTRAINT "PK_subs_subscribers" PRIMARY KEY (id);


--
-- Name: subscriber_invoices PK_subscriber_invoices; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.subscriber_invoices
    ADD CONSTRAINT "PK_subscriber_invoices" PRIMARY KEY (subscriber_id, invoice_id);


--
-- Name: lang_dictionaries lang_dictionaries_pkey; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.lang_dictionaries
    ADD CONSTRAINT lang_dictionaries_pkey PRIMARY KEY (dict_id);


--
-- Name: lang_translations lang_translations_pkey; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.lang_translations
    ADD CONSTRAINT lang_translations_pkey PRIMARY KEY (dict_id, sentence);


--
-- Name: EmailIndex; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "EmailIndex" ON public."AspNetUsers" USING btree ("NormalizedEmail");


--
-- Name: IX_AddressInvoices_InvoiceDataId; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_AddressInvoices_InvoiceDataId" ON public."AddressInvoices" USING btree ("InvoiceDataId");


--
-- Name: IX_ApiKeys_StoreId; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_ApiKeys_StoreId" ON public."ApiKeys" USING btree ("StoreId");


--
-- Name: IX_ApiKeys_UserId; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_ApiKeys_UserId" ON public."ApiKeys" USING btree ("UserId");


--
-- Name: IX_Apps_StoreDataId; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_Apps_StoreDataId" ON public."Apps" USING btree ("StoreDataId");


--
-- Name: IX_AspNetRoleClaims_RoleId; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_AspNetRoleClaims_RoleId" ON public."AspNetRoleClaims" USING btree ("RoleId");


--
-- Name: IX_AspNetUserClaims_UserId; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_AspNetUserClaims_UserId" ON public."AspNetUserClaims" USING btree ("UserId");


--
-- Name: IX_AspNetUserLogins_UserId; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_AspNetUserLogins_UserId" ON public."AspNetUserLogins" USING btree ("UserId");


--
-- Name: IX_AspNetUserRoles_RoleId; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_AspNetUserRoles_RoleId" ON public."AspNetUserRoles" USING btree ("RoleId");


--
-- Name: IX_Fido2Credentials_ApplicationUserId; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_Fido2Credentials_ApplicationUserId" ON public."Fido2Credentials" USING btree ("ApplicationUserId");


--
-- Name: IX_Files_ApplicationUserId; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_Files_ApplicationUserId" ON public."Files" USING btree ("ApplicationUserId");


--
-- Name: IX_Forms_StoreId; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_Forms_StoreId" ON public."Forms" USING btree ("StoreId");


--
-- Name: IX_InvoiceEvents_InvoiceDataId; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_InvoiceEvents_InvoiceDataId" ON public."InvoiceEvents" USING btree ("InvoiceDataId");


--
-- Name: IX_InvoiceSearches_InvoiceDataId; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_InvoiceSearches_InvoiceDataId" ON public."InvoiceSearches" USING btree ("InvoiceDataId");


--
-- Name: IX_InvoiceSearches_Value; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_InvoiceSearches_Value" ON public."InvoiceSearches" USING btree ("Value");


--
-- Name: IX_InvoiceWebhookDeliveries_DeliveryId; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_InvoiceWebhookDeliveries_DeliveryId" ON public."InvoiceWebhookDeliveries" USING btree ("DeliveryId");


--
-- Name: IX_Invoices_Created; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_Invoices_Created" ON public."Invoices" USING btree ("Created");


--
-- Name: IX_Invoices_Metadata_ItemCode; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_Invoices_Metadata_ItemCode" ON public."Invoices" USING btree (public.get_itemcode("Blob2")) WHERE (public.get_itemcode("Blob2") IS NOT NULL);


--
-- Name: IX_Invoices_Metadata_OrderId; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_Invoices_Metadata_OrderId" ON public."Invoices" USING btree (public.get_orderid("Blob2")) WHERE (public.get_orderid("Blob2") IS NOT NULL);


--
-- Name: IX_Invoices_Pending; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_Invoices_Pending" ON public."Invoices" USING btree ((1)) WHERE public.is_pending("Status");


--
-- Name: IX_Invoices_StoreDataId; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_Invoices_StoreDataId" ON public."Invoices" USING btree ("StoreDataId");


--
-- Name: IX_LightningAddresses_StoreDataId; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_LightningAddresses_StoreDataId" ON public."LightningAddresses" USING btree ("StoreDataId");


--
-- Name: IX_Notifications_ApplicationUserId; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_Notifications_ApplicationUserId" ON public."Notifications" USING btree ("ApplicationUserId");


--
-- Name: IX_PairedSINData_SIN; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_PairedSINData_SIN" ON public."PairedSINData" USING btree ("SIN");


--
-- Name: IX_PairedSINData_StoreDataId; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_PairedSINData_StoreDataId" ON public."PairedSINData" USING btree ("StoreDataId");


--
-- Name: IX_PaymentRequests_StoreDataId; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_PaymentRequests_StoreDataId" ON public."PaymentRequests" USING btree ("StoreDataId");


--
-- Name: IX_Payments_InvoiceDataId; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_Payments_InvoiceDataId" ON public."Payments" USING btree ("InvoiceDataId");


--
-- Name: IX_Payments_Pending; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_Payments_Pending" ON public."Payments" USING btree ((1)) WHERE public.is_pending("Status");


--
-- Name: IX_PayoutProcessors_StoreId; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_PayoutProcessors_StoreId" ON public."PayoutProcessors" USING btree ("StoreId");


--
-- Name: IX_Payouts_DedupId_State; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_Payouts_DedupId_State" ON public."Payouts" USING btree ("DedupId", "State");


--
-- Name: IX_Payouts_PullPaymentDataId; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_Payouts_PullPaymentDataId" ON public."Payouts" USING btree ("PullPaymentDataId");


--
-- Name: IX_Payouts_State; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_Payouts_State" ON public."Payouts" USING btree ("State");


--
-- Name: IX_Payouts_StoreDataId; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_Payouts_StoreDataId" ON public."Payouts" USING btree ("StoreDataId");


--
-- Name: IX_PendingTransactions_StoreId; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_PendingTransactions_StoreId" ON public."PendingTransactions" USING btree ("StoreId");


--
-- Name: IX_PendingTransactions_TransactionId; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_PendingTransactions_TransactionId" ON public."PendingTransactions" USING btree ("TransactionId");


--
-- Name: IX_PullPayments_StoreId; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_PullPayments_StoreId" ON public."PullPayments" USING btree ("StoreId");


--
-- Name: IX_Refunds_PullPaymentDataId; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_Refunds_PullPaymentDataId" ON public."Refunds" USING btree ("PullPaymentDataId");


--
-- Name: IX_StoreRoles_StoreDataId_Role; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE UNIQUE INDEX "IX_StoreRoles_StoreDataId_Role" ON public."StoreRoles" USING btree ("StoreDataId", "Role");


--
-- Name: IX_U2FDevices_ApplicationUserId; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_U2FDevices_ApplicationUserId" ON public."U2FDevices" USING btree ("ApplicationUserId");


--
-- Name: IX_UserStore_StoreDataId; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_UserStore_StoreDataId" ON public."UserStore" USING btree ("StoreDataId");


--
-- Name: IX_WalletObjectLinks_WalletId_BType_BId; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_WalletObjectLinks_WalletId_BType_BId" ON public."WalletObjectLinks" USING btree ("WalletId", "BType", "BId");


--
-- Name: IX_WalletObjects_Type_Id; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_WalletObjects_Type_Id" ON public."WalletObjects" USING btree ("Type", "Id");


--
-- Name: IX_WebhookDeliveries_Timestamp; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_WebhookDeliveries_Timestamp" ON public."WebhookDeliveries" USING btree ("Timestamp") WHERE ("Pruned" IS FALSE);


--
-- Name: IX_WebhookDeliveries_WebhookId; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_WebhookDeliveries_WebhookId" ON public."WebhookDeliveries" USING btree ("WebhookId");


--
-- Name: IX_customers_store_id_external_ref; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE UNIQUE INDEX "IX_customers_store_id_external_ref" ON public.customers USING btree (store_id, external_ref);


--
-- Name: IX_email_rules_offering_id; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_email_rules_offering_id" ON public.email_rules USING btree (offering_id);


--
-- Name: IX_email_rules_store_id; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_email_rules_store_id" ON public.email_rules USING btree (store_id);


--
-- Name: IX_store_label_links_store_id_object_id; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_store_label_links_store_id_object_id" ON public.store_label_links USING btree (store_id, object_id);


--
-- Name: IX_store_labels_store_id_type_text_lower; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE UNIQUE INDEX "IX_store_labels_store_id_type_text_lower" ON public.store_labels USING btree (store_id, type, lower(text));


--
-- Name: IX_subs_features_offering_id_custom_id; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE UNIQUE INDEX "IX_subs_features_offering_id_custom_id" ON public.subs_features USING btree (offering_id, custom_id);


--
-- Name: IX_subs_offerings_app_id; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_subs_offerings_app_id" ON public.subs_offerings USING btree (app_id);


--
-- Name: IX_subs_plan_changes_plan_change_id; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_subs_plan_changes_plan_change_id" ON public.subs_plan_changes USING btree (plan_change_id);


--
-- Name: IX_subs_plan_checkouts_expiration; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_subs_plan_checkouts_expiration" ON public.subs_plan_checkouts USING btree (expiration);


--
-- Name: IX_subs_plan_checkouts_invoice_id; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_subs_plan_checkouts_invoice_id" ON public.subs_plan_checkouts USING btree (invoice_id);


--
-- Name: IX_subs_plan_checkouts_plan_id; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_subs_plan_checkouts_plan_id" ON public.subs_plan_checkouts USING btree (plan_id);


--
-- Name: IX_subs_plan_checkouts_subscriber_id; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_subs_plan_checkouts_subscriber_id" ON public.subs_plan_checkouts USING btree (subscriber_id);


--
-- Name: IX_subs_plans_features_feature_id; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_subs_plans_features_feature_id" ON public.subs_plans_features USING btree (feature_id);


--
-- Name: IX_subs_plans_offering_id; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_subs_plans_offering_id" ON public.subs_plans USING btree (offering_id);


--
-- Name: IX_subs_portal_sessions_expiration; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_subs_portal_sessions_expiration" ON public.subs_portal_sessions USING btree (expiration);


--
-- Name: IX_subs_portal_sessions_subscriber_id; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_subs_portal_sessions_subscriber_id" ON public.subs_portal_sessions USING btree (subscriber_id);


--
-- Name: IX_subs_subscriber_credits_history_subscriber_id_created_at; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_subs_subscriber_credits_history_subscriber_id_created_at" ON public.subs_subscriber_credits_history USING btree (subscriber_id DESC, created_at DESC);


--
-- Name: IX_subs_subscriber_credits_history_subscriber_id_currency; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_subs_subscriber_credits_history_subscriber_id_currency" ON public.subs_subscriber_credits_history USING btree (subscriber_id, currency);


--
-- Name: IX_subs_subscribers_customer_id; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_subs_subscribers_customer_id" ON public.subs_subscribers USING btree (customer_id);


--
-- Name: IX_subs_subscribers_new_plan_id; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_subs_subscribers_new_plan_id" ON public.subs_subscribers USING btree (new_plan_id);


--
-- Name: IX_subs_subscribers_offering_id_customer_id; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE UNIQUE INDEX "IX_subs_subscribers_offering_id_customer_id" ON public.subs_subscribers USING btree (offering_id, customer_id);


--
-- Name: IX_subs_subscribers_plan_id; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_subs_subscribers_plan_id" ON public.subs_subscribers USING btree (plan_id);


--
-- Name: IX_subscriber_invoices_invoice_id; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_subscriber_invoices_invoice_id" ON public.subscriber_invoices USING btree (invoice_id);


--
-- Name: IX_subscriber_invoices_subscriber_id_created_at; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX "IX_subscriber_invoices_subscriber_id_created_at" ON public.subscriber_invoices USING btree (subscriber_id, created_at);


--
-- Name: RoleNameIndex; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE UNIQUE INDEX "RoleNameIndex" ON public."AspNetRoles" USING btree ("NormalizedName");


--
-- Name: UserNameIndex; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE UNIQUE INDEX "UserNameIndex" ON public."AspNetUsers" USING btree ("NormalizedUserName");


--
-- Name: ix_paymentrequests_storedataid_referenceid; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE UNIQUE INDEX ix_paymentrequests_storedataid_referenceid ON public."PaymentRequests" USING btree ("StoreDataId", "ReferenceId") WHERE ("ReferenceId" IS NOT NULL);


--
-- Name: AddressInvoices FK_AddressInvoices_Invoices_InvoiceDataId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."AddressInvoices"
    ADD CONSTRAINT "FK_AddressInvoices_Invoices_InvoiceDataId" FOREIGN KEY ("InvoiceDataId") REFERENCES public."Invoices"("Id") ON DELETE CASCADE;


--
-- Name: ApiKeys FK_ApiKeys_AspNetUsers_UserId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."ApiKeys"
    ADD CONSTRAINT "FK_ApiKeys_AspNetUsers_UserId" FOREIGN KEY ("UserId") REFERENCES public."AspNetUsers"("Id") ON DELETE CASCADE;


--
-- Name: ApiKeys FK_ApiKeys_Stores_StoreId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."ApiKeys"
    ADD CONSTRAINT "FK_ApiKeys_Stores_StoreId" FOREIGN KEY ("StoreId") REFERENCES public."Stores"("Id") ON DELETE CASCADE;


--
-- Name: Apps FK_Apps_Stores_StoreDataId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."Apps"
    ADD CONSTRAINT "FK_Apps_Stores_StoreDataId" FOREIGN KEY ("StoreDataId") REFERENCES public."Stores"("Id") ON DELETE CASCADE;


--
-- Name: AspNetRoleClaims FK_AspNetRoleClaims_AspNetRoles_RoleId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."AspNetRoleClaims"
    ADD CONSTRAINT "FK_AspNetRoleClaims_AspNetRoles_RoleId" FOREIGN KEY ("RoleId") REFERENCES public."AspNetRoles"("Id") ON DELETE CASCADE;


--
-- Name: AspNetUserClaims FK_AspNetUserClaims_AspNetUsers_UserId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."AspNetUserClaims"
    ADD CONSTRAINT "FK_AspNetUserClaims_AspNetUsers_UserId" FOREIGN KEY ("UserId") REFERENCES public."AspNetUsers"("Id") ON DELETE CASCADE;


--
-- Name: AspNetUserLogins FK_AspNetUserLogins_AspNetUsers_UserId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."AspNetUserLogins"
    ADD CONSTRAINT "FK_AspNetUserLogins_AspNetUsers_UserId" FOREIGN KEY ("UserId") REFERENCES public."AspNetUsers"("Id") ON DELETE CASCADE;


--
-- Name: AspNetUserRoles FK_AspNetUserRoles_AspNetRoles_RoleId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."AspNetUserRoles"
    ADD CONSTRAINT "FK_AspNetUserRoles_AspNetRoles_RoleId" FOREIGN KEY ("RoleId") REFERENCES public."AspNetRoles"("Id") ON DELETE CASCADE;


--
-- Name: AspNetUserRoles FK_AspNetUserRoles_AspNetUsers_UserId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."AspNetUserRoles"
    ADD CONSTRAINT "FK_AspNetUserRoles_AspNetUsers_UserId" FOREIGN KEY ("UserId") REFERENCES public."AspNetUsers"("Id") ON DELETE CASCADE;


--
-- Name: AspNetUserTokens FK_AspNetUserTokens_AspNetUsers_UserId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."AspNetUserTokens"
    ADD CONSTRAINT "FK_AspNetUserTokens_AspNetUsers_UserId" FOREIGN KEY ("UserId") REFERENCES public."AspNetUsers"("Id") ON DELETE CASCADE;


--
-- Name: Fido2Credentials FK_Fido2Credentials_AspNetUsers_ApplicationUserId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."Fido2Credentials"
    ADD CONSTRAINT "FK_Fido2Credentials_AspNetUsers_ApplicationUserId" FOREIGN KEY ("ApplicationUserId") REFERENCES public."AspNetUsers"("Id") ON DELETE CASCADE;


--
-- Name: Files FK_Files_AspNetUsers_ApplicationUserId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."Files"
    ADD CONSTRAINT "FK_Files_AspNetUsers_ApplicationUserId" FOREIGN KEY ("ApplicationUserId") REFERENCES public."AspNetUsers"("Id") ON DELETE RESTRICT;


--
-- Name: Forms FK_Forms_Stores_StoreId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."Forms"
    ADD CONSTRAINT "FK_Forms_Stores_StoreId" FOREIGN KEY ("StoreId") REFERENCES public."Stores"("Id") ON DELETE CASCADE;


--
-- Name: InvoiceEvents FK_InvoiceEvents_Invoices_InvoiceDataId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."InvoiceEvents"
    ADD CONSTRAINT "FK_InvoiceEvents_Invoices_InvoiceDataId" FOREIGN KEY ("InvoiceDataId") REFERENCES public."Invoices"("Id") ON DELETE CASCADE;


--
-- Name: InvoiceSearches FK_InvoiceSearches_Invoices_InvoiceDataId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."InvoiceSearches"
    ADD CONSTRAINT "FK_InvoiceSearches_Invoices_InvoiceDataId" FOREIGN KEY ("InvoiceDataId") REFERENCES public."Invoices"("Id") ON DELETE CASCADE;


--
-- Name: InvoiceWebhookDeliveries FK_InvoiceWebhookDeliveries_Invoices_InvoiceId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."InvoiceWebhookDeliveries"
    ADD CONSTRAINT "FK_InvoiceWebhookDeliveries_Invoices_InvoiceId" FOREIGN KEY ("InvoiceId") REFERENCES public."Invoices"("Id") ON DELETE CASCADE;


--
-- Name: InvoiceWebhookDeliveries FK_InvoiceWebhookDeliveries_WebhookDeliveries_DeliveryId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."InvoiceWebhookDeliveries"
    ADD CONSTRAINT "FK_InvoiceWebhookDeliveries_WebhookDeliveries_DeliveryId" FOREIGN KEY ("DeliveryId") REFERENCES public."WebhookDeliveries"("Id") ON DELETE CASCADE;


--
-- Name: Invoices FK_Invoices_Stores_StoreDataId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."Invoices"
    ADD CONSTRAINT "FK_Invoices_Stores_StoreDataId" FOREIGN KEY ("StoreDataId") REFERENCES public."Stores"("Id") ON DELETE CASCADE;


--
-- Name: LightningAddresses FK_LightningAddresses_Stores_StoreDataId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."LightningAddresses"
    ADD CONSTRAINT "FK_LightningAddresses_Stores_StoreDataId" FOREIGN KEY ("StoreDataId") REFERENCES public."Stores"("Id") ON DELETE CASCADE;


--
-- Name: Notifications FK_Notifications_AspNetUsers_ApplicationUserId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."Notifications"
    ADD CONSTRAINT "FK_Notifications_AspNetUsers_ApplicationUserId" FOREIGN KEY ("ApplicationUserId") REFERENCES public."AspNetUsers"("Id") ON DELETE CASCADE;


--
-- Name: PairedSINData FK_PairedSINData_Stores_StoreDataId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."PairedSINData"
    ADD CONSTRAINT "FK_PairedSINData_Stores_StoreDataId" FOREIGN KEY ("StoreDataId") REFERENCES public."Stores"("Id") ON DELETE CASCADE;


--
-- Name: PaymentRequests FK_PaymentRequests_Stores_StoreDataId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."PaymentRequests"
    ADD CONSTRAINT "FK_PaymentRequests_Stores_StoreDataId" FOREIGN KEY ("StoreDataId") REFERENCES public."Stores"("Id") ON DELETE CASCADE;


--
-- Name: Payments FK_Payments_Invoices_InvoiceDataId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."Payments"
    ADD CONSTRAINT "FK_Payments_Invoices_InvoiceDataId" FOREIGN KEY ("InvoiceDataId") REFERENCES public."Invoices"("Id") ON DELETE CASCADE;


--
-- Name: PayoutProcessors FK_PayoutProcessors_Stores_StoreId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."PayoutProcessors"
    ADD CONSTRAINT "FK_PayoutProcessors_Stores_StoreId" FOREIGN KEY ("StoreId") REFERENCES public."Stores"("Id") ON DELETE CASCADE;


--
-- Name: Payouts FK_Payouts_PullPayments_PullPaymentDataId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."Payouts"
    ADD CONSTRAINT "FK_Payouts_PullPayments_PullPaymentDataId" FOREIGN KEY ("PullPaymentDataId") REFERENCES public."PullPayments"("Id") ON DELETE CASCADE;


--
-- Name: Payouts FK_Payouts_Stores_StoreDataId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."Payouts"
    ADD CONSTRAINT "FK_Payouts_Stores_StoreDataId" FOREIGN KEY ("StoreDataId") REFERENCES public."Stores"("Id") ON DELETE CASCADE;


--
-- Name: PendingTransactions FK_PendingTransactions_Stores_StoreId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."PendingTransactions"
    ADD CONSTRAINT "FK_PendingTransactions_Stores_StoreId" FOREIGN KEY ("StoreId") REFERENCES public."Stores"("Id") ON DELETE CASCADE;


--
-- Name: PullPayments FK_PullPayments_Stores_StoreId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."PullPayments"
    ADD CONSTRAINT "FK_PullPayments_Stores_StoreId" FOREIGN KEY ("StoreId") REFERENCES public."Stores"("Id") ON DELETE CASCADE;


--
-- Name: Refunds FK_Refunds_Invoices_InvoiceDataId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."Refunds"
    ADD CONSTRAINT "FK_Refunds_Invoices_InvoiceDataId" FOREIGN KEY ("InvoiceDataId") REFERENCES public."Invoices"("Id") ON DELETE CASCADE;


--
-- Name: Refunds FK_Refunds_PullPayments_PullPaymentDataId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."Refunds"
    ADD CONSTRAINT "FK_Refunds_PullPayments_PullPaymentDataId" FOREIGN KEY ("PullPaymentDataId") REFERENCES public."PullPayments"("Id") ON DELETE CASCADE;


--
-- Name: StoreRoles FK_StoreRoles_Stores_StoreDataId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."StoreRoles"
    ADD CONSTRAINT "FK_StoreRoles_Stores_StoreDataId" FOREIGN KEY ("StoreDataId") REFERENCES public."Stores"("Id") ON DELETE CASCADE;


--
-- Name: StoreSettings FK_StoreSettings_Stores_StoreId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."StoreSettings"
    ADD CONSTRAINT "FK_StoreSettings_Stores_StoreId" FOREIGN KEY ("StoreId") REFERENCES public."Stores"("Id") ON DELETE CASCADE;


--
-- Name: StoreWebhooks FK_StoreWebhooks_Stores_StoreId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."StoreWebhooks"
    ADD CONSTRAINT "FK_StoreWebhooks_Stores_StoreId" FOREIGN KEY ("StoreId") REFERENCES public."Stores"("Id") ON DELETE CASCADE;


--
-- Name: StoreWebhooks FK_StoreWebhooks_Webhooks_WebhookId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."StoreWebhooks"
    ADD CONSTRAINT "FK_StoreWebhooks_Webhooks_WebhookId" FOREIGN KEY ("WebhookId") REFERENCES public."Webhooks"("Id") ON DELETE CASCADE;


--
-- Name: U2FDevices FK_U2FDevices_AspNetUsers_ApplicationUserId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."U2FDevices"
    ADD CONSTRAINT "FK_U2FDevices_AspNetUsers_ApplicationUserId" FOREIGN KEY ("ApplicationUserId") REFERENCES public."AspNetUsers"("Id") ON DELETE CASCADE;


--
-- Name: UserStore FK_UserStore_AspNetUsers_ApplicationUserId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."UserStore"
    ADD CONSTRAINT "FK_UserStore_AspNetUsers_ApplicationUserId" FOREIGN KEY ("ApplicationUserId") REFERENCES public."AspNetUsers"("Id") ON DELETE CASCADE;


--
-- Name: UserStore FK_UserStore_StoreRoles_Role; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."UserStore"
    ADD CONSTRAINT "FK_UserStore_StoreRoles_Role" FOREIGN KEY ("Role") REFERENCES public."StoreRoles"("Id");


--
-- Name: UserStore FK_UserStore_Stores_StoreDataId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."UserStore"
    ADD CONSTRAINT "FK_UserStore_Stores_StoreDataId" FOREIGN KEY ("StoreDataId") REFERENCES public."Stores"("Id") ON DELETE CASCADE;


--
-- Name: WalletObjectLinks FK_WalletObjectLinks_WalletObjects_WalletId_AType_AId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."WalletObjectLinks"
    ADD CONSTRAINT "FK_WalletObjectLinks_WalletObjects_WalletId_AType_AId" FOREIGN KEY ("WalletId", "AType", "AId") REFERENCES public."WalletObjects"("WalletId", "Type", "Id") ON DELETE CASCADE;


--
-- Name: WalletObjectLinks FK_WalletObjectLinks_WalletObjects_WalletId_BType_BId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."WalletObjectLinks"
    ADD CONSTRAINT "FK_WalletObjectLinks_WalletObjects_WalletId_BType_BId" FOREIGN KEY ("WalletId", "BType", "BId") REFERENCES public."WalletObjects"("WalletId", "Type", "Id") ON DELETE CASCADE;


--
-- Name: WalletTransactions FK_WalletTransactions_Wallets_WalletDataId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."WalletTransactions"
    ADD CONSTRAINT "FK_WalletTransactions_Wallets_WalletDataId" FOREIGN KEY ("WalletDataId") REFERENCES public."Wallets"("Id") ON DELETE CASCADE;


--
-- Name: WebhookDeliveries FK_WebhookDeliveries_Webhooks_WebhookId; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public."WebhookDeliveries"
    ADD CONSTRAINT "FK_WebhookDeliveries_Webhooks_WebhookId" FOREIGN KEY ("WebhookId") REFERENCES public."Webhooks"("Id") ON DELETE CASCADE;


--
-- Name: boltcards FK_boltcards_PullPayments; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.boltcards
    ADD CONSTRAINT "FK_boltcards_PullPayments" FOREIGN KEY (ppid) REFERENCES public."PullPayments"("Id") ON DELETE SET NULL;


--
-- Name: customers FK_customers_Stores_store_id; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT "FK_customers_Stores_store_id" FOREIGN KEY (store_id) REFERENCES public."Stores"("Id") ON DELETE CASCADE;


--
-- Name: customers_identities FK_customers_identities_customers_customer_id; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.customers_identities
    ADD CONSTRAINT "FK_customers_identities_customers_customer_id" FOREIGN KEY (customer_id) REFERENCES public.customers(id) ON DELETE CASCADE;


--
-- Name: email_rules FK_email_rules_Stores_store_id; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.email_rules
    ADD CONSTRAINT "FK_email_rules_Stores_store_id" FOREIGN KEY (store_id) REFERENCES public."Stores"("Id") ON DELETE CASCADE;


--
-- Name: email_rules FK_email_rules_subs_offerings_offering_id; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.email_rules
    ADD CONSTRAINT "FK_email_rules_subs_offerings_offering_id" FOREIGN KEY (offering_id) REFERENCES public.subs_offerings(id) ON DELETE CASCADE;


--
-- Name: store_label_links FK_store_label_links_store_labels_store_id_store_label_id; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.store_label_links
    ADD CONSTRAINT "FK_store_label_links_store_labels_store_id_store_label_id" FOREIGN KEY (store_id, store_label_id) REFERENCES public.store_labels(store_id, id) ON DELETE CASCADE;


--
-- Name: subs_features FK_subs_features_subs_offerings_offering_id; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.subs_features
    ADD CONSTRAINT "FK_subs_features_subs_offerings_offering_id" FOREIGN KEY (offering_id) REFERENCES public.subs_offerings(id) ON DELETE CASCADE;


--
-- Name: subs_offerings FK_subs_offerings_Apps_app_id; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.subs_offerings
    ADD CONSTRAINT "FK_subs_offerings_Apps_app_id" FOREIGN KEY (app_id) REFERENCES public."Apps"("Id") ON DELETE CASCADE;


--
-- Name: subs_plan_changes FK_subs_plan_changes_subs_plans_plan_change_id; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.subs_plan_changes
    ADD CONSTRAINT "FK_subs_plan_changes_subs_plans_plan_change_id" FOREIGN KEY (plan_change_id) REFERENCES public.subs_plans(id) ON DELETE CASCADE;


--
-- Name: subs_plan_changes FK_subs_plan_changes_subs_plans_plan_id; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.subs_plan_changes
    ADD CONSTRAINT "FK_subs_plan_changes_subs_plans_plan_id" FOREIGN KEY (plan_id) REFERENCES public.subs_plans(id) ON DELETE CASCADE;


--
-- Name: subs_plan_checkouts FK_subs_plan_checkouts_Invoices_invoice_id; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.subs_plan_checkouts
    ADD CONSTRAINT "FK_subs_plan_checkouts_Invoices_invoice_id" FOREIGN KEY (invoice_id) REFERENCES public."Invoices"("Id") ON DELETE SET NULL;


--
-- Name: subs_plan_checkouts FK_subs_plan_checkouts_subs_plans_plan_id; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.subs_plan_checkouts
    ADD CONSTRAINT "FK_subs_plan_checkouts_subs_plans_plan_id" FOREIGN KEY (plan_id) REFERENCES public.subs_plans(id) ON DELETE CASCADE;


--
-- Name: subs_plan_checkouts FK_subs_plan_checkouts_subs_subscribers_subscriber_id; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.subs_plan_checkouts
    ADD CONSTRAINT "FK_subs_plan_checkouts_subs_subscribers_subscriber_id" FOREIGN KEY (subscriber_id) REFERENCES public.subs_subscribers(id) ON DELETE SET NULL;


--
-- Name: subs_plans_features FK_subs_plans_features_subs_features_feature_id; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.subs_plans_features
    ADD CONSTRAINT "FK_subs_plans_features_subs_features_feature_id" FOREIGN KEY (feature_id) REFERENCES public.subs_features(id) ON DELETE CASCADE;


--
-- Name: subs_plans_features FK_subs_plans_features_subs_plans_plan_id; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.subs_plans_features
    ADD CONSTRAINT "FK_subs_plans_features_subs_plans_plan_id" FOREIGN KEY (plan_id) REFERENCES public.subs_plans(id) ON DELETE CASCADE;


--
-- Name: subs_plans FK_subs_plans_subs_offerings_offering_id; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.subs_plans
    ADD CONSTRAINT "FK_subs_plans_subs_offerings_offering_id" FOREIGN KEY (offering_id) REFERENCES public.subs_offerings(id) ON DELETE CASCADE;


--
-- Name: subs_portal_sessions FK_subs_portal_sessions_subs_subscribers_subscriber_id; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.subs_portal_sessions
    ADD CONSTRAINT "FK_subs_portal_sessions_subs_subscribers_subscriber_id" FOREIGN KEY (subscriber_id) REFERENCES public.subs_subscribers(id) ON DELETE CASCADE;


--
-- Name: subs_subscriber_credits_history FK_subs_subscriber_credits_history_subs_subscriber_credits_sub~; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.subs_subscriber_credits_history
    ADD CONSTRAINT "FK_subs_subscriber_credits_history_subs_subscriber_credits_sub~" FOREIGN KEY (subscriber_id, currency) REFERENCES public.subs_subscriber_credits(subscriber_id, currency) ON DELETE CASCADE;


--
-- Name: subs_subscriber_credits FK_subs_subscriber_credits_subs_subscribers_subscriber_id; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.subs_subscriber_credits
    ADD CONSTRAINT "FK_subs_subscriber_credits_subs_subscribers_subscriber_id" FOREIGN KEY (subscriber_id) REFERENCES public.subs_subscribers(id) ON DELETE CASCADE;


--
-- Name: subs_subscribers FK_subs_subscribers_customers_customer_id; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.subs_subscribers
    ADD CONSTRAINT "FK_subs_subscribers_customers_customer_id" FOREIGN KEY (customer_id) REFERENCES public.customers(id) ON DELETE CASCADE;


--
-- Name: subs_subscribers FK_subs_subscribers_subs_offerings_offering_id; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.subs_subscribers
    ADD CONSTRAINT "FK_subs_subscribers_subs_offerings_offering_id" FOREIGN KEY (offering_id) REFERENCES public.subs_offerings(id) ON DELETE CASCADE;


--
-- Name: subs_subscribers FK_subs_subscribers_subs_plans_new_plan_id; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.subs_subscribers
    ADD CONSTRAINT "FK_subs_subscribers_subs_plans_new_plan_id" FOREIGN KEY (new_plan_id) REFERENCES public.subs_plans(id) ON DELETE SET NULL;


--
-- Name: subs_subscribers FK_subs_subscribers_subs_plans_plan_id; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.subs_subscribers
    ADD CONSTRAINT "FK_subs_subscribers_subs_plans_plan_id" FOREIGN KEY (plan_id) REFERENCES public.subs_plans(id) ON DELETE CASCADE;


--
-- Name: subscriber_invoices FK_subscriber_invoices_Invoices_invoice_id; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.subscriber_invoices
    ADD CONSTRAINT "FK_subscriber_invoices_Invoices_invoice_id" FOREIGN KEY (invoice_id) REFERENCES public."Invoices"("Id") ON DELETE CASCADE;


--
-- Name: subscriber_invoices FK_subscriber_invoices_subs_subscribers_subscriber_id; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.subscriber_invoices
    ADD CONSTRAINT "FK_subscriber_invoices_subs_subscribers_subscriber_id" FOREIGN KEY (subscriber_id) REFERENCES public.subs_subscribers(id) ON DELETE CASCADE;


--
-- Name: lang_dictionaries lang_dictionaries_fallback_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.lang_dictionaries
    ADD CONSTRAINT lang_dictionaries_fallback_fkey FOREIGN KEY (fallback) REFERENCES public.lang_dictionaries(dict_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: lang_translations lang_translations_dict_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.lang_translations
    ADD CONSTRAINT lang_translations_dict_id_fkey FOREIGN KEY (dict_id) REFERENCES public.lang_dictionaries(dict_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict r7wckYNljaWhtD9ZzjGLevQeMnjm6IaHiOma1eALuQW7jcIOSxd5cJhhvtF1egn

--
-- Database "nbxplorer" dump
--

--
-- PostgreSQL database dump
--

\restrict XL2amhRKrxbzBPIQJAUyLe6ewvyrv79h5o9wIunQACDRugm0cdJBq5m2YpvxFLC

-- Dumped from database version 16.13
-- Dumped by pg_dump version 16.13

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: nbxplorer; Type: DATABASE; Schema: -; Owner: agentyk
--

CREATE DATABASE nbxplorer WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';


ALTER DATABASE nbxplorer OWNER TO agentyk;

\unrestrict XL2amhRKrxbzBPIQJAUyLe6ewvyrv79h5o9wIunQACDRugm0cdJBq5m2YpvxFLC
\connect nbxplorer
\restrict XL2amhRKrxbzBPIQJAUyLe6ewvyrv79h5o9wIunQACDRugm0cdJBq5m2YpvxFLC

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: nbxv1_ds; Type: TYPE; Schema: public; Owner: agentyk
--

CREATE TYPE public.nbxv1_ds AS (
	descriptor text,
	idx bigint,
	script text,
	metadata jsonb,
	addr text,
	used boolean
);


ALTER TYPE public.nbxv1_ds OWNER TO agentyk;

--
-- Name: new_in; Type: TYPE; Schema: public; Owner: agentyk
--

CREATE TYPE public.new_in AS (
	tx_id text,
	idx bigint,
	spent_tx_id text,
	spent_idx bigint
);


ALTER TYPE public.new_in OWNER TO agentyk;

--
-- Name: new_out; Type: TYPE; Schema: public; Owner: agentyk
--

CREATE TYPE public.new_out AS (
	tx_id text,
	idx bigint,
	script text,
	value bigint,
	asset_id text
);


ALTER TYPE public.new_out OWNER TO agentyk;

--
-- Name: outpoint; Type: TYPE; Schema: public; Owner: agentyk
--

CREATE TYPE public.outpoint AS (
	tx_id text,
	idx bigint
);


ALTER TYPE public.outpoint OWNER TO agentyk;

--
-- Name: blks_confirmed_update_txs(); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.blks_confirmed_update_txs() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	r RECORD;
	maturity_height BIGINT;
BEGIN
  IF NEW.confirmed = OLD.confirmed THEN
	RETURN NEW;
  END IF;
  IF NEW.confirmed IS TRUE THEN
	-- TODO: We assume 100 blocks for immaturity. We should probably make this data configurable on separate table.
	maturity_height := (SELECT height - 100 + 1 FROM get_tip(NEW.code));
	-- Turn immature flag of outputs to mature
	-- Note that we never set the outputs back to immature, even in reorg
	-- But that's such a corner case that we don't care.
	WITH q AS (
	  SELECT t.code, tx_id FROM txs t
	  JOIN blks b ON b.code=t.code AND b.blk_id=t.blk_id
	  WHERE t.code=NEW.code AND t.immature IS TRUE AND b.height < maturity_height
	)
	UPDATE txs t SET immature='f' 
	FROM q
	WHERE t.code=q.code AND t.tx_id=q.tx_id;
	-- Turn mempool flag of confirmed txs to false
	WITH q AS (
	SELECT t.code, t.tx_id, bt.blk_id, bt.blk_idx, b.height FROM txs t
	JOIN blks_txs bt USING (code, tx_id)
	JOIN blks b ON b.code=t.code AND b.blk_id=bt.blk_id
	WHERE t.code=NEW.code AND bt.blk_id=NEW.blk_id)
	UPDATE txs t SET mempool='f', replaced_by=NULL, blk_id=q.blk_id, blk_idx=q.blk_idx, blk_height=q.height
	FROM q
	WHERE t.code=q.code AND t.tx_id=q.tx_id;
	-- Turn mempool flag of txs with inputs spent by confirmed blocks to false
	WITH q AS (
	SELECT mempool_ins.code, mempool_ins.tx_id mempool_tx_id, confirmed_ins.tx_id confirmed_tx_id
	FROM 
	  (SELECT i.code, i.spent_tx_id, i.spent_idx, t.tx_id FROM ins i
	  JOIN txs t USING (code, tx_id)
	  WHERE i.code=NEW.code AND t.mempool IS TRUE) mempool_ins
	LEFT JOIN (
	  SELECT i.code, i.spent_tx_id, i.spent_idx, t.tx_id FROM ins i
	  JOIN txs t USING (code, tx_id)
	  WHERE i.code=NEW.code AND t.blk_id = NEW.blk_id
	) confirmed_ins USING (code, spent_tx_id, spent_idx)
	WHERE confirmed_ins.tx_id IS NOT NULL) -- The use of LEFT JOIN is intentional, it forces postgres to use a specific index
	UPDATE txs t SET mempool='f', replaced_by=q.confirmed_tx_id
	FROM q
	WHERE t.code=q.code AND t.tx_id=q.mempool_tx_id;
  ELSE -- IF not confirmed anymore
	-- Set mempool flags of the txs in the blocks back to true
	WITH q AS (
	  SELECT code, tx_id FROM blks_txs
	  WHERE code=NEW.code AND blk_id=NEW.blk_id
	)
	-- We can't query over txs.blk_id directly, because it doesn't have an index
	UPDATE txs t
	SET mempool='t', blk_id=NULL, blk_idx=NULL, blk_height=NULL
	FROM q
	WHERE t.code=q.code AND t.tx_id = q.tx_id;
  END IF;
  -- Remove from spent_outs all outputs whose tx isn't in the mempool anymore
  DELETE FROM spent_outs so
  WHERE so.code = NEW.code
  AND NOT EXISTS (
    -- Returns true if any tx referenced by the spent_out is in the mempool
    SELECT 1 FROM txs
    WHERE code=so.code AND mempool IS TRUE AND tx_id = ANY(ARRAY[so.tx_id, so.spent_by, so.prev_spent_by]));
  RETURN NEW;
END
$$;


ALTER FUNCTION public.blks_confirmed_update_txs() OWNER TO agentyk;

--
-- Name: blks_txs_denormalize(); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.blks_txs_denormalize() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	r RECORD;
BEGIN
	SELECT confirmed, height INTO r FROM blks WHERE code=NEW.code AND blk_id=NEW.blk_id;
	IF 
	  r.confirmed IS TRUE
	THEN
	  -- Propagate values to txs
	  UPDATE txs
	  SET blk_id=NEW.blk_id, blk_idx=NEW.blk_idx, blk_height=r.height, mempool='f', replaced_by=NULL
	  WHERE code=NEW.code AND tx_id=NEW.tx_id;
	END IF;
	RETURN NEW;
END
$$;


ALTER FUNCTION public.blks_txs_denormalize() OWNER TO agentyk;

--
-- Name: descriptors_scripts_after_insert_or_update_trigger_proc(); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.descriptors_scripts_after_insert_or_update_trigger_proc() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  last_idx BIGINT;
BEGIN
  IF TG_OP='UPDATE' AND NEW.used IS NOT DISTINCT FROM OLD.used THEN
	RETURN NEW;
  END IF;

  IF TG_OP='INSERT' THEN
	-- Inherit the used flag of the script.
	NEW.used = (SELECT used FROM scripts WHERE code=NEW.code AND script=NEW.script);

	-- Bump next_idx if idx is greater or equal to it.
	-- Note that if the script is used, then the gap is now 0. But if not, the gap increased same value as the next_idx increase.
	UPDATE descriptors d
	  SET next_idx = NEW.idx + 1, gap=(CASE WHEN NEW.used THEN 0 ELSE d.gap + (NEW.idx + 1) - d.next_idx END)
	  WHERE code=NEW.code AND descriptor=NEW.descriptor AND next_idx < NEW.idx + 1;

	-- Early exit, we already updated the gap correctly. No need for some potentially expensive scan if used is false.
	IF FOUND THEN
	  RETURN NEW;
	END IF;
  END IF;

  -- Now we want to update the gap
  IF NEW.used THEN
	--  [1] [2] [3] [4] [5] then next_idx=6, imagine that 3 is now used, we want to update gap to be 2 (because we still have 2 addresses ahead)
	UPDATE descriptors d
	SET gap = next_idx - NEW.idx - 1 -- 6 - 3 - 1 = 2
	WHERE code=NEW.code AND descriptor=NEW.descriptor AND gap > next_idx - NEW.idx - 1; -- If an address has been used, the gap can't do up by definition
  ELSE -- If not used anymore, we need to scan descriptors_scripts to find the latest used.
	last_idx := (SELECT MAX(ds.idx) FROM descriptors_scripts ds WHERE ds.code=NEW.code AND ds.descriptor=NEW.descriptor AND ds.used IS TRUE AND ds.idx != NEW.idx);
	UPDATE descriptors d
	-- Say 1 and 3 was used. Then the newest latest used address will be 1 (last_idx) and gap should be 4 (gap = 6 - 1 - 1)
	SET gap = COALESCE(next_idx - last_idx - 1, next_idx)
	-- If the index was less than 1, then it couldn't have changed the gap... except if there is no last_idx
	WHERE code=NEW.code AND descriptor=NEW.descriptor  AND (last_idx IS NULL OR NEW.idx > last_idx); 
  END IF;
  RETURN NEW;
END $$;


ALTER FUNCTION public.descriptors_scripts_after_insert_or_update_trigger_proc() OWNER TO agentyk;

--
-- Name: descriptors_scripts_wallets_scripts_trigger_proc(); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.descriptors_scripts_wallets_scripts_trigger_proc() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  r RECORD;
BEGIN
  INSERT INTO wallets_scripts AS ws (code, script, wallet_id)
  SELECT ds.code, ds.script, wd.wallet_id FROM new_descriptors_scripts ds
  JOIN wallets_descriptors wd USING (code, descriptor)
  ON CONFLICT (code, script, wallet_id) DO UPDATE SET ref_count = ws.ref_count + 1;
  RETURN NULL;
END $$;


ALTER FUNCTION public.descriptors_scripts_wallets_scripts_trigger_proc() OWNER TO agentyk;

--
-- Name: fetch_matches(text, public.new_out[], public.new_in[]); Type: PROCEDURE; Schema: public; Owner: agentyk
--

CREATE PROCEDURE public.fetch_matches(IN in_code text, IN in_outs public.new_out[], IN in_ins public.new_in[])
    LANGUAGE plpgsql
    AS $$
DECLARE
  has_match BOOLEAN;
BEGIN
  CALL fetch_matches(in_code, in_outs, in_ins, has_match);
END $$;


ALTER PROCEDURE public.fetch_matches(IN in_code text, IN in_outs public.new_out[], IN in_ins public.new_in[]) OWNER TO agentyk;

--
-- Name: fetch_matches(text, public.new_out[], public.new_in[], boolean); Type: PROCEDURE; Schema: public; Owner: agentyk
--

CREATE PROCEDURE public.fetch_matches(IN in_code text, IN in_outs public.new_out[], IN in_ins public.new_in[], INOUT has_match boolean)
    LANGUAGE plpgsql
    AS $$
BEGIN
	BEGIN
	  TRUNCATE TABLE matched_outs, matched_ins, matched_conflicts, new_ins;
	EXCEPTION WHEN others THEN
	  CREATE TEMPORARY TABLE IF NOT EXISTS matched_outs (LIKE new_out);
	  ALTER TABLE matched_outs ADD COLUMN IF NOT EXISTS "order" BIGINT;
	  CREATE TEMPORARY TABLE IF NOT EXISTS new_ins (LIKE new_in);
	  ALTER TABLE new_ins ADD COLUMN IF NOT EXISTS "order" BIGINT;
	  ALTER TABLE new_ins ADD COLUMN IF NOT EXISTS code TEXT;
	  CREATE TEMPORARY TABLE IF NOT EXISTS matched_ins (LIKE new_ins);
	  ALTER TABLE matched_ins ADD COLUMN IF NOT EXISTS script TEXT;
	  ALTER TABLE matched_ins ADD COLUMN IF NOT EXISTS value bigint;
	  ALTER TABLE matched_ins ADD COLUMN IF NOT EXISTS asset_id TEXT;
	  CREATE TEMPORARY TABLE IF NOT EXISTS matched_conflicts (
		code TEXT,
		spent_tx_id TEXT,
		spent_idx BIGINT,
		replacing_tx_id TEXT,
		replaced_tx_id TEXT,
		is_new BOOLEAN);
	END;
	has_match := 'f';
	INSERT INTO matched_outs
	SELECT o.* FROM scripts s
	JOIN unnest(in_outs)  WITH ORDINALITY AS o(tx_id, idx, script, value, asset_id, "order") USING (script)
	WHERE s.code=in_code
	ORDER BY "order";
	-- Fancy way to remove dups (https://stackoverflow.com/questions/6583916/delete-duplicate-rows-from-small-table)
	DELETE FROM matched_outs a USING (
      SELECT MIN(ctid) as ctid, tx_id, idx
        FROM matched_outs
        GROUP BY tx_id, idx HAVING COUNT(*) > 1
      ) b
      WHERE a.tx_id = b.tx_id AND a.idx = b.idx
      AND a.ctid <> b.ctid;
	-- This table will include only the ins we need to add to the spent_outs for double spend detection
	INSERT INTO new_ins
	SELECT i.*, in_code code FROM unnest(in_ins) WITH ORDINALITY AS i(tx_id, idx, spent_tx_id, spent_idx, "order");
	INSERT INTO matched_ins
	SELECT * FROM
	  (SELECT i.*, o.script, o.value, o.asset_id  FROM new_ins i
	  JOIN outs o ON o.code=i.code AND o.tx_id=i.spent_tx_id AND o.idx=i.spent_idx
	  UNION ALL
	  SELECT i.*, o.script, o.value, o.asset_id  FROM new_ins i
	  JOIN matched_outs o ON i.spent_tx_id = o.tx_id AND i.spent_idx = o.idx) i
	ORDER BY "order";
	DELETE FROM new_ins
	WHERE NOT tx_id=ANY(SELECT tx_id FROM matched_ins UNION SELECT tx_id FROM matched_outs)
	AND NOT (spent_tx_id || spent_idx::TEXT)=ANY(SELECT (tx_id || idx::TEXT) FROM spent_outs);
	INSERT INTO matched_conflicts
	WITH RECURSIVE cte(code, spent_tx_id, spent_idx, replacing_tx_id, replaced_tx_id) AS
	(
	  SELECT 
		in_code code,
		i.spent_tx_id,
		i.spent_idx,
		i.tx_id replacing_tx_id,
		CASE
			WHEN so.spent_by != i.tx_id THEN so.spent_by
			ELSE so.prev_spent_by
		END replaced_tx_id,
		so.spent_by != i.tx_id is_new
	  FROM new_ins i
	  JOIN spent_outs so ON so.code=in_code AND so.tx_id=i.spent_tx_id AND so.idx=i.spent_idx
	  JOIN txs rt ON so.code=rt.code AND rt.tx_id=so.spent_by
	  WHERE rt.code=in_code AND rt.mempool IS TRUE
	  UNION
	  SELECT c.code, c.spent_tx_id, c.spent_idx, c.replacing_tx_id, i.tx_id replaced_tx_id, c.is_new FROM cte c
	  JOIN outs o ON o.code=c.code AND o.tx_id=c.replaced_tx_id
	  JOIN ins i ON i.code=c.code AND i.spent_tx_id=o.tx_id AND i.spent_idx=o.idx
	  WHERE i.code=c.code AND i.mempool IS TRUE
	)
	SELECT * FROM cte;
	DELETE FROM matched_ins a USING (
      SELECT MIN(ctid) as ctid, tx_id, idx
        FROM matched_ins
        GROUP BY tx_id, idx HAVING COUNT(*) > 1
      ) b
      WHERE a.tx_id = b.tx_id AND a.idx = b.idx
      AND a.ctid <> b.ctid;
	DELETE FROM matched_conflicts a USING (
      SELECT MIN(ctid) as ctid, replaced_tx_id
        FROM matched_conflicts
        GROUP BY replaced_tx_id HAVING COUNT(*) > 1
      ) b
      WHERE a.replaced_tx_id = b.replaced_tx_id
      AND a.ctid <> b.ctid;
	-- Make order start by 0, as most languages have array starting by 0
	UPDATE matched_ins i
	SET "order"=i."order" - 1;
	IF FOUND THEN
	  has_match := 't';
	END IF;
	UPDATE matched_outs o
	SET "order"=o."order" - 1;
	IF FOUND THEN
	  has_match := 't';
	END IF;
	PERFORM 1 FROM matched_conflicts WHERE is_new IS TRUE LIMIT 1;
	IF FOUND THEN
	  has_match := 't';
	END IF;
END $$;


ALTER PROCEDURE public.fetch_matches(IN in_code text, IN in_outs public.new_out[], IN in_ins public.new_in[], INOUT has_match boolean) OWNER TO agentyk;

--
-- Name: generate_series_fixed(timestamp with time zone, timestamp with time zone, interval); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.generate_series_fixed(in_from timestamp with time zone, in_to timestamp with time zone, in_interval interval) RETURNS TABLE(s timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
  SELECT generate_series(in_from, in_to, in_interval)
  LIMIT  (EXTRACT(EPOCH FROM (in_to - in_from))/EXTRACT(EPOCH FROM in_interval)) + 1; -- I am unsure about the exact formula, but over estimating 1 row is fine...
$$;


ALTER FUNCTION public.generate_series_fixed(in_from timestamp with time zone, in_to timestamp with time zone, in_interval interval) OWNER TO agentyk;

--
-- Name: get_tip(text); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.get_tip(in_code text) RETURNS TABLE(code text, blk_id text, height bigint, prev_id text)
    LANGUAGE sql STABLE
    AS $$
  SELECT code, blk_id, height, prev_id FROM blks WHERE code=in_code AND confirmed IS TRUE ORDER BY height DESC LIMIT 1
$$;


ALTER FUNCTION public.get_tip(in_code text) OWNER TO agentyk;

--
-- Name: get_wallets_histogram(text, text, text, timestamp with time zone, timestamp with time zone, interval); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.get_wallets_histogram(in_wallet_id text, in_code text, in_asset_id text, in_from timestamp with time zone, in_to timestamp with time zone, in_interval interval) RETURNS TABLE(date timestamp with time zone, balance_change bigint, balance bigint)
    LANGUAGE sql STABLE
    AS $$
  SELECT s AS time,
  		change::bigint,
  		(SUM (q.change) OVER (ORDER BY s) + COALESCE((SELECT balance_total FROM wallets_history WHERE seen_at < in_from AND wallet_id=in_wallet_id AND code=in_code AND asset_id=in_asset_id ORDER BY seen_at DESC, blk_height DESC, blk_idx DESC LIMIT 1), 0))::BIGINT  AS balance
  FROM generate_series_fixed(in_from, in_to - in_interval, in_interval) s
  LEFT JOIN LATERAL (
	  SELECT s, COALESCE(SUM(balance_change),0) change FROM wallets_history
	  WHERE  s <= seen_at AND seen_at < s + in_interval AND wallet_id=in_wallet_id AND code=in_code AND asset_id=in_asset_id
  ) q USING (s)
$$;


ALTER FUNCTION public.get_wallets_histogram(in_wallet_id text, in_code text, in_asset_id text, in_from timestamp with time zone, in_to timestamp with time zone, in_interval interval) OWNER TO agentyk;

--
-- Name: get_wallets_recent(text, interval, integer, integer); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.get_wallets_recent(in_wallet_id text, in_interval interval, in_limit integer, in_offset integer) RETURNS TABLE(code text, asset_id text, tx_id text, seen_at timestamp with time zone, balance_change bigint, balance_total bigint)
    LANGUAGE sql STABLE
    AS $$
  SELECT * FROM get_wallets_recent(in_wallet_id, NULL, NULL, in_interval, in_limit, in_offset)
$$;


ALTER FUNCTION public.get_wallets_recent(in_wallet_id text, in_interval interval, in_limit integer, in_offset integer) OWNER TO agentyk;

--
-- Name: get_wallets_recent(text, text, interval, integer, integer); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.get_wallets_recent(in_wallet_id text, in_code text, in_interval interval, in_limit integer, in_offset integer) RETURNS TABLE(code text, asset_id text, tx_id text, seen_at timestamp with time zone, balance_change bigint, balance_total bigint)
    LANGUAGE sql STABLE
    AS $$
  SELECT * FROM get_wallets_recent(in_wallet_id, in_code, NULL, in_interval, in_limit, in_offset)
$$;


ALTER FUNCTION public.get_wallets_recent(in_wallet_id text, in_code text, in_interval interval, in_limit integer, in_offset integer) OWNER TO agentyk;

--
-- Name: get_wallets_recent(text, text, text, interval, integer, integer); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.get_wallets_recent(in_wallet_id text, in_code text, in_asset_id text, in_interval interval, in_limit integer, in_offset integer) RETURNS TABLE(code text, asset_id text, tx_id text, seen_at timestamp with time zone, balance_change bigint, balance_total bigint)
    LANGUAGE sql STABLE
    AS $$
  WITH this_balances AS MATERIALIZED (
	  SELECT code, asset_id, unconfirmed_balance FROM wallets_balances
	  WHERE wallet_id=in_wallet_id
  ),
  latest_txs AS (
	SELECT  io.code,
			io.asset_id,
			blk_idx,
			blk_height,
			tx_id,
			seen_at,
			COALESCE(SUM (value) FILTER (WHERE is_out IS TRUE), 0) -  COALESCE(SUM (value) FILTER (WHERE is_out IS FALSE), 0) balance_change
		FROM ins_outs io
		JOIN wallets_scripts ws USING (code, script)
		WHERE ((CURRENT_TIMESTAMP - in_interval) <= seen_at) AND
		      (in_code IS NULL OR in_code=io.code) AND
			  (in_asset_id IS NULL OR in_asset_id=io.asset_id) AND
			  (blk_id IS NOT NULL OR (mempool IS TRUE AND replaced_by IS NULL)) AND
			  wallet_id=in_wallet_id
		GROUP BY io.code, io.asset_id, tx_id, seen_at, blk_height, blk_idx
		ORDER BY seen_at DESC, blk_height DESC, blk_idx DESC, asset_id
	LIMIT in_limit + in_offset
  )
  SELECT q.code, q.asset_id, q.tx_id, q.seen_at, q.balance_change::BIGINT, (COALESCE((q.latest_balance - LAG(balance_change_sum, 1) OVER (PARTITION BY code, asset_id ORDER BY seen_at DESC, blk_height DESC, blk_idx DESC)), q.latest_balance))::BIGINT balance_total FROM
	  (SELECT q.*,
			  COALESCE((SELECT unconfirmed_balance FROM this_balances WHERE code=q.code AND asset_id=q.asset_id), 0) latest_balance,
			  SUM(q.balance_change) OVER (PARTITION BY code, asset_id ORDER BY seen_at DESC, blk_height DESC, blk_idx DESC) balance_change_sum FROM 
		  latest_txs q
	  ) q
  ORDER BY seen_at DESC, blk_height DESC, blk_idx DESC, asset_id
  OFFSET in_offset
$$;


ALTER FUNCTION public.get_wallets_recent(in_wallet_id text, in_code text, in_asset_id text, in_interval interval, in_limit integer, in_offset integer) OWNER TO agentyk;

--
-- Name: ins_after_insert2_trigger_proc(); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.ins_after_insert2_trigger_proc() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  r RECORD;
BEGIN
  IF NEW.blk_id IS NOT NULL OR (NEW.mempool IS TRUE AND NEW.replaced_by IS NULL)  THEN
	UPDATE outs SET input_tx_id=NEW.tx_id, input_idx=NEW.idx, input_mempool=NEW.mempool
	WHERE (code=NEW.code AND tx_id=NEW.spent_tx_id AND idx=NEW.spent_idx);
  END IF;
  RETURN NEW;
END
$$;


ALTER FUNCTION public.ins_after_insert2_trigger_proc() OWNER TO agentyk;

--
-- Name: ins_after_insert_trigger_proc(); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.ins_after_insert_trigger_proc() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  r RECORD;
BEGIN
  -- Duplicate the ins into the ins_outs table
  INSERT INTO ins_outs
  SELECT
	i.code,
	i.tx_id,
	i.idx,
	'f',
	i.spent_tx_id,
	i.spent_idx,
	i.script,
	i.value,
	i.asset_id,
	NULL,
	t.blk_id,
	t.blk_idx,
	t.blk_height,
	t.mempool,
	t.replaced_by,
	t.seen_at
	FROM new_ins i
	JOIN txs t USING (code, tx_id);

  RETURN NULL;
END
$$;


ALTER FUNCTION public.ins_after_insert_trigger_proc() OWNER TO agentyk;

--
-- Name: ins_after_update_trigger_proc(); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.ins_after_update_trigger_proc() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  r RECORD;
BEGIN
  -- Just (un)confirmed? Update the out's spent_by
  IF NEW.blk_id IS DISTINCT FROM OLD.blk_id THEN
	  UPDATE outs SET input_tx_id=NEW.tx_id, input_idx=NEW.idx, input_mempool=NEW.mempool
	  WHERE (code=NEW.code AND tx_id=NEW.spent_tx_id AND idx=NEW.spent_idx);
  END IF;

  -- Kicked off mempool? If it's replaced or not in blk anymore, update outs spent_by
  IF (NEW.mempool IS FALSE AND OLD.mempool IS TRUE) AND (NEW.replaced_by IS NOT NULL OR NEW.blk_id IS NULL) THEN
	  UPDATE outs SET input_tx_id=NULL, input_idx=NULL, input_mempool='f'
	  WHERE (code=NEW.code AND tx_id=NEW.spent_tx_id AND idx=NEW.spent_idx) AND (input_tx_id=NEW.tx_id AND input_idx=NEW.idx);
  END IF;

  RETURN NEW;
END
$$;


ALTER FUNCTION public.ins_after_update_trigger_proc() OWNER TO agentyk;

--
-- Name: ins_before_insert_trigger_proc(); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.ins_before_insert_trigger_proc() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  r RECORD;
BEGIN
   -- Take the denormalized values from the associated tx, and spent outs, put them in the inserted
  SELECT * INTO r FROM txs WHERE code=NEW.code AND tx_id=NEW.tx_id;
  NEW.blk_id = r.blk_id;
  NEW.blk_id = r.blk_id;
  NEW.mempool = r.mempool;
  NEW.replaced_by = r.replaced_by;
  NEW.seen_at = r.seen_at;
  SELECT * INTO r FROM outs WHERE code=NEW.code AND tx_id=NEW.spent_tx_id AND idx=NEW.spent_idx;
  IF NOT FOUND THEN
	RETURN NULL;
  END IF;
  NEW.script = r.script;
  NEW.value = r.value;
  NEW.asset_id = r.asset_id;
  RETURN NEW;
END
$$;


ALTER FUNCTION public.ins_before_insert_trigger_proc() OWNER TO agentyk;

--
-- Name: ins_delete_ins_outs(); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.ins_delete_ins_outs() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  DELETE FROM ins_outs io WHERE io.code=OLD.code AND io.tx_id=OLD.tx_id AND io.idx=OLD.idx AND io.is_out IS FALSE;
  RETURN OLD;
END
$$;


ALTER FUNCTION public.ins_delete_ins_outs() OWNER TO agentyk;

--
-- Name: nbxv1_get_descriptor_id(text, text, text); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.nbxv1_get_descriptor_id(in_code text, in_scheme text, in_feature text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
	   SELECT encode(substring(sha256((in_code || '|' || in_scheme || '|' || in_feature)::bytea), 0, 22), 'base64')
$$;


ALTER FUNCTION public.nbxv1_get_descriptor_id(in_code text, in_scheme text, in_feature text) OWNER TO agentyk;

--
-- Name: nbxv1_get_keypath(jsonb, bigint); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.nbxv1_get_keypath(metadata jsonb, idx bigint) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
	   SELECT REPLACE(metadata->>'keyPathTemplate', '*', idx::TEXT)
$$;


ALTER FUNCTION public.nbxv1_get_keypath(metadata jsonb, idx bigint) OWNER TO agentyk;

--
-- Name: nbxv1_get_keypath_index(jsonb, text); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.nbxv1_get_keypath_index(metadata jsonb, keypath text) RETURNS bigint
    LANGUAGE sql IMMUTABLE
    AS $_$
  SELECT
  CASE WHEN keypath LIKE (prefix || '%') AND 
            keypath LIKE ('%' || suffix) AND
            idx ~ '^\d+$'
       THEN CAST(idx AS BIGINT) END
  FROM (SELECT SUBSTRING(
              keypath
              FROM LENGTH(prefix) + 1
              FOR LENGTH(keypath) - LENGTH(prefix) - LENGTH(suffix)
          ) idx, prefix, suffix
      FROM (
      SELECT
          split_part(metadata->>'keyPathTemplate', '*', 1) AS prefix,
          split_part(metadata->>'keyPathTemplate', '*', 2) AS suffix
      ) parts) q;
$_$;


ALTER FUNCTION public.nbxv1_get_keypath_index(metadata jsonb, keypath text) OWNER TO agentyk;

--
-- Name: nbxv1_get_wallet_id(text, text); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.nbxv1_get_wallet_id(in_code text, in_scheme_or_address text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
	   SELECT encode(substring(sha256((in_code || '|' || in_scheme_or_address)::bytea), 0, 22), 'base64')
$$;


ALTER FUNCTION public.nbxv1_get_wallet_id(in_code text, in_scheme_or_address text) OWNER TO agentyk;

--
-- Name: outs_after_update_trigger_proc(); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.outs_after_update_trigger_proc() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.asset_id IS DISTINCT FROM OLD.asset_id OR NEW.value IS DISTINCT FROM OLD.value THEN
	WITH cte AS (
	UPDATE ins SET asset_id=NEW.asset_id, value=NEW.value
	WHERE code=NEW.code AND spent_tx_id=NEW.tx_id AND spent_idx=NEW.idx
	RETURNING code, tx_id, idx)
	UPDATE ins_outs io SET asset_id=NEW.asset_id, value=NEW.value
	FROM cte
	WHERE cte.code=io.code AND cte.tx_id=io.tx_id AND cte.idx=io.idx AND is_out IS FALSE;

	UPDATE ins_outs SET asset_id=NEW.asset_id, value=NEW.value
	WHERE code=NEW.code AND tx_id=NEW.tx_id AND idx=NEW.idx AND is_out IS TRUE;
  END IF;
  RETURN NULL;
END
$$;


ALTER FUNCTION public.outs_after_update_trigger_proc() OWNER TO agentyk;

--
-- Name: outs_delete_ins_outs(); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.outs_delete_ins_outs() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  DELETE FROM ins_outs io WHERE io.code=OLD.code AND io.tx_id=OLD.tx_id AND io.idx=OLD.idx AND io.is_out IS TRUE;
  DELETE FROM ins_outs io WHERE io.code=OLD.code AND io.spent_tx_id=OLD.tx_id AND io.spent_idx=OLD.idx AND io.is_out IS FALSE;
  RETURN OLD;
END
$$;


ALTER FUNCTION public.outs_delete_ins_outs() OWNER TO agentyk;

--
-- Name: outs_denormalize_from_tx(); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.outs_denormalize_from_tx() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  r RECORD;
BEGIN
  SELECT * INTO r FROM txs WHERE code=NEW.code AND tx_id=NEW.tx_id;
  IF r IS NULL THEN
	RETURN NEW; -- This will crash on foreign key constraint
  END IF;
  NEW.immature = r.immature;
  NEW.blk_id = r.blk_id;
  NEW.blk_idx = r.blk_idx;
  NEW.blk_height = r.blk_height;
  NEW.mempool = r.mempool;
  NEW.replaced_by = r.replaced_by;
  NEW.seen_at = r.seen_at;
  RETURN NEW;
END
$$;


ALTER FUNCTION public.outs_denormalize_from_tx() OWNER TO agentyk;

--
-- Name: outs_denormalize_to_ins_outs(); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.outs_denormalize_to_ins_outs() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  r RECORD;
BEGIN
  INSERT INTO ins_outs
  SELECT
	o.code,
	o.tx_id,
	o.idx,
	't',
	NULL,
	NULL,
	o.script,
	o.value,
	o.asset_id,
	o.immature,
	t.blk_id,
	t.blk_idx,
	t.blk_height,
	t.mempool,
	t.replaced_by,
	t.seen_at
	FROM new_outs o
	JOIN txs t ON t.code=o.code AND t.tx_id=o.tx_id;
	-- Mark scripts as used
	FOR r IN SELECT * FROM new_outs
	LOOP
	  UPDATE scripts
		SET used='t'
		WHERE code=r.code AND script=r.script AND used IS FALSE;
	END LOOP;
	RETURN NULL;
END
$$;


ALTER FUNCTION public.outs_denormalize_to_ins_outs() OWNER TO agentyk;

--
-- Name: save_matches(text); Type: PROCEDURE; Schema: public; Owner: agentyk
--

CREATE PROCEDURE public.save_matches(IN in_code text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  CALL save_matches (in_code, CURRENT_TIMESTAMP);
END $$;


ALTER PROCEDURE public.save_matches(IN in_code text) OWNER TO agentyk;

--
-- Name: save_matches(text, timestamp with time zone); Type: PROCEDURE; Schema: public; Owner: agentyk
--

CREATE PROCEDURE public.save_matches(IN in_code text, IN in_seen_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
DECLARE
  r RECORD;
BEGIN
  
  INSERT INTO txs (code, tx_id, seen_at)
  SELECT in_code, q.tx_id, in_seen_at FROM
  (
	SELECT tx_id FROM matched_outs
	UNION
	SELECT tx_id FROM matched_ins
    UNION
    SELECT replacing_tx_id FROM matched_conflicts
  ) q
  ON CONFLICT (code, tx_id)
  DO UPDATE SET seen_at=in_seen_at
  WHERE in_seen_at < txs.seen_at;
  INSERT INTO outs (code, tx_id, idx, script, value, asset_id)
  SELECT in_code, tx_id, idx, script, value, asset_id
  FROM matched_outs
  ON CONFLICT DO NOTHING;
  INSERT INTO ins (code, tx_id, idx, spent_tx_id, spent_idx)
  SELECT in_code, tx_id, idx, spent_tx_id, spent_idx
  FROM matched_ins
  ON CONFLICT DO NOTHING;
  INSERT INTO spent_outs
  SELECT in_code, spent_tx_id, spent_idx, tx_id FROM new_ins
  ON CONFLICT DO NOTHING;
  FOR r IN
	SELECT * FROM matched_conflicts WHERE is_new IS TRUE
  LOOP
	UPDATE spent_outs SET spent_by=r.replacing_tx_id, prev_spent_by=r.replaced_tx_id
	WHERE code=r.code AND tx_id=r.spent_tx_id AND idx=r.spent_idx;
	UPDATE txs SET replaced_by=r.replacing_tx_id
	WHERE code=r.code AND tx_id=r.replaced_tx_id;
  END LOOP;
END $$;


ALTER PROCEDURE public.save_matches(IN in_code text, IN in_seen_at timestamp with time zone) OWNER TO agentyk;

--
-- Name: save_matches(text, public.new_out[], public.new_in[]); Type: PROCEDURE; Schema: public; Owner: agentyk
--

CREATE PROCEDURE public.save_matches(IN in_code text, IN in_outs public.new_out[], IN in_ins public.new_in[])
    LANGUAGE plpgsql
    AS $$
BEGIN
  CALL save_matches (in_code, in_outs, in_ins, CURRENT_TIMESTAMP);
END $$;


ALTER PROCEDURE public.save_matches(IN in_code text, IN in_outs public.new_out[], IN in_ins public.new_in[]) OWNER TO agentyk;

--
-- Name: save_matches(text, public.new_out[], public.new_in[], timestamp with time zone); Type: PROCEDURE; Schema: public; Owner: agentyk
--

CREATE PROCEDURE public.save_matches(IN in_code text, IN in_outs public.new_out[], IN in_ins public.new_in[], IN in_seen_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
  CALL fetch_matches (in_code, in_outs, in_ins);
  CALL save_matches(in_code, in_seen_at);
END $$;


ALTER PROCEDURE public.save_matches(IN in_code text, IN in_outs public.new_out[], IN in_ins public.new_in[], IN in_seen_at timestamp with time zone) OWNER TO agentyk;

--
-- Name: scripts_set_descriptors_scripts_used(); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.scripts_set_descriptors_scripts_used() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.used != OLD.used AND NEW.used IS TRUE THEN
    UPDATE descriptors_scripts ds SET used='t' WHERE code=NEW.code AND script=NEW.script AND used='f';
  END IF;
  RETURN NEW;
END $$;


ALTER FUNCTION public.scripts_set_descriptors_scripts_used() OWNER TO agentyk;

--
-- Name: to_btc(bigint); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.to_btc(v bigint) RETURNS numeric
    LANGUAGE sql IMMUTABLE
    AS $$
	   SELECT ROUND(v::NUMERIC / 100000000, 8)
$$;


ALTER FUNCTION public.to_btc(v bigint) OWNER TO agentyk;

--
-- Name: to_btc(numeric); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.to_btc(v numeric) RETURNS numeric
    LANGUAGE sql IMMUTABLE
    AS $$
	   SELECT ROUND(v / 100000000, 8)
$$;


ALTER FUNCTION public.to_btc(v numeric) OWNER TO agentyk;

--
-- Name: txs_denormalize(); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.txs_denormalize() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	r RECORD;
BEGIN
  -- Propagate any change to table outs, ins, and ins_outs
	UPDATE outs o SET  immature=NEW.immature, blk_id = NEW.blk_id, blk_idx = NEW.blk_idx, blk_height = NEW.blk_height, mempool = NEW.mempool, replaced_by = NEW.replaced_by, seen_at = NEW.seen_at
	WHERE o.code=NEW.code AND o.tx_id=NEW.tx_id;

	UPDATE ins i SET  blk_id = NEW.blk_id, blk_idx = NEW.blk_idx, blk_height = NEW.blk_height, mempool = NEW.mempool, replaced_by = NEW.replaced_by, seen_at = NEW.seen_at
	WHERE i.code=NEW.code AND i.tx_id=NEW.tx_id;

	UPDATE ins_outs io SET  immature=NEW.immature, blk_id = NEW.blk_id, blk_idx = NEW.blk_idx, blk_height = NEW.blk_height, mempool = NEW.mempool, replaced_by = NEW.replaced_by, seen_at = NEW.seen_at
	WHERE io.code=NEW.code AND io.tx_id=NEW.tx_id;

	-- Propagate any replaced_by / mempool to ins/outs/ins_outs and to the children
	IF NEW.replaced_by IS DISTINCT FROM OLD.replaced_by THEN
	  FOR r IN 
	  	SELECT code, tx_id, replaced_by FROM ins
		WHERE code=NEW.code AND spent_tx_id=NEW.tx_id AND replaced_by IS DISTINCT FROM NEW.replaced_by
	  LOOP
		UPDATE txs SET replaced_by=NEW.replaced_by
		WHERE code=r.code AND tx_id=r.tx_id;
	  END LOOP;
	END IF;

	IF NEW.mempool != OLD.mempool AND (NEW.mempool IS TRUE OR NEW.blk_id IS NULL) THEN
	  FOR r IN 
	  	SELECT code, tx_id, mempool FROM ins
		WHERE code=NEW.code AND spent_tx_id=NEW.tx_id AND mempool != NEW.mempool
	  LOOP
		UPDATE txs SET mempool=NEW.mempool
		WHERE code=r.code AND tx_id=r.tx_id;
	  END LOOP;
	END IF;

	RETURN NEW;
END
$$;


ALTER FUNCTION public.txs_denormalize() OWNER TO agentyk;

--
-- Name: wallets_descriptors_after_delete_trigger_proc(); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.wallets_descriptors_after_delete_trigger_proc() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  WITH cte AS (
	SELECT ds.code, ds.script, wd.wallet_id FROM new_wallets_descriptors wd
	JOIN descriptors_scripts ds USING (code, descriptor)
  )
  UPDATE wallets_scripts ws
  SET ref_count = ws.ref_count - 1
  FROM cte
  WHERE cte.code=ws.code AND cte.script=ws.script AND cte.wallet_id=ws.wallet_id;
  RETURN NULL;
END;
$$;


ALTER FUNCTION public.wallets_descriptors_after_delete_trigger_proc() OWNER TO agentyk;

--
-- Name: wallets_descriptors_after_insert_trigger_proc(); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.wallets_descriptors_after_insert_trigger_proc() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO wallets_scripts AS ws (code, script, wallet_id)
	  SELECT ds.code, ds.script, wd.wallet_id FROM new_wallets_descriptors wd
	  JOIN descriptors_scripts ds USING (code, descriptor)
  ON CONFLICT (code, script, wallet_id) DO UPDATE SET ref_count = ws.ref_count + 1;
  RETURN NULL;
END;
$$;


ALTER FUNCTION public.wallets_descriptors_after_insert_trigger_proc() OWNER TO agentyk;

--
-- Name: wallets_history_refresh(); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.wallets_history_refresh() RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
  last_ins_outs TIMESTAMPTZ;
  last_wallets_history TIMESTAMPTZ;
BEGIN
   IF pg_try_advisory_xact_lock(75639) IS FALSE THEN
	RETURN FALSE;
   END IF;
   last_ins_outs := (SELECT max(seen_at) FROM ins_outs WHERE blk_id IS NOT NULL);
   last_wallets_history := (SELECT max(seen_at) FROM wallets_history);
   IF last_wallets_history IS DISTINCT FROM last_ins_outs THEN
	REFRESH MATERIALIZED VIEW CONCURRENTLY wallets_history;
	RETURN TRUE;
   END IF;
   RETURN FALSE;
EXCEPTION WHEN OTHERS THEN
  RETURN FALSE;
END
$$;


ALTER FUNCTION public.wallets_history_refresh() OWNER TO agentyk;

--
-- Name: wallets_scripts_after_delete_trigger_proc(); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.wallets_scripts_after_delete_trigger_proc() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (SELECT COUNT(*) FROM new_wallets_scripts) = 0 THEN
  	RETURN NULL;
  END IF;
  WITH cte AS (
	SELECT ww.parent_id, nws.code, nws.script FROM new_wallets_scripts nws
	JOIN wallets_wallets ww ON ww.wallet_id=nws.wallet_id
	JOIN wallets_scripts ws ON ws.code=nws.code AND ws.script=nws.script AND ws.wallet_id=ww.parent_id
  )
  UPDATE wallets_scripts ws
  SET ref_count = ws.ref_count -1
  FROM cte
  WHERE cte.code=ws.code AND cte.script=ws.script AND cte.parent_id=ws.wallet_id;
  RETURN NULL;
END;
$$;


ALTER FUNCTION public.wallets_scripts_after_delete_trigger_proc() OWNER TO agentyk;

--
-- Name: wallets_scripts_after_insert_trigger_proc(); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.wallets_scripts_after_insert_trigger_proc() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF (SELECT COUNT(*) FROM new_wallets_scripts) = 0 THEN
  	RETURN NULL;
  END IF;
  INSERT INTO wallets_scripts AS ws (code, script, wallet_id)
  SELECT nws.code, nws.script, ww.parent_id FROM new_wallets_scripts nws
  JOIN wallets_wallets ww ON ww.wallet_id=nws.wallet_id
  ON CONFLICT (code, script, wallet_id) DO UPDATE SET ref_count = ws.ref_count + 1;
  RETURN NULL;
END;
$$;


ALTER FUNCTION public.wallets_scripts_after_insert_trigger_proc() OWNER TO agentyk;

--
-- Name: wallets_scripts_after_update_trigger_proc(); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.wallets_scripts_after_update_trigger_proc() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  WITH cte AS (
	SELECT code, script, wallet_id FROM new_wallets_scripts
	WHERE ref_count <= 0
  )
  DELETE FROM wallets_scripts AS ws
  USING cte c
  WHERE c.code=ws.code AND c.script=ws.script AND c.wallet_id=ws.wallet_id;
  RETURN NULL;
END;
$$;


ALTER FUNCTION public.wallets_scripts_after_update_trigger_proc() OWNER TO agentyk;

--
-- Name: wallets_wallets_after_delete_trigger_proc(); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.wallets_wallets_after_delete_trigger_proc() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	WITH cte AS (
	  SELECT pws.code, pws.script, pws.wallet_id FROM new_wallets_wallets ww
	  JOIN wallets_scripts cws ON cws.wallet_id=ww.wallet_id
	  JOIN wallets_scripts pws ON pws.wallet_id=ww.parent_id AND cws.code=pws.code AND cws.script=pws.script
	)
	UPDATE wallets_scripts ws
	SET ref_count = ws.ref_count - 1
	FROM cte c
	WHERE c.code=ws.code AND c.script=ws.script AND c.wallet_id=ws.wallet_id;
  RETURN NULL;
END;
$$;


ALTER FUNCTION public.wallets_wallets_after_delete_trigger_proc() OWNER TO agentyk;

--
-- Name: wallets_wallets_after_insert_trigger_proc(); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.wallets_wallets_after_insert_trigger_proc() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO wallets_scripts AS ws (code, script, wallet_id)
  SELECT ws.code, ws.script, ww.parent_id FROM new_wallets_wallets ww
  JOIN wallets_scripts ws ON ws.wallet_id=ww.wallet_id
  ON CONFLICT (code, script, wallet_id) DO UPDATE SET ref_count = ws.ref_count + 1;
  RETURN NULL;
END;
$$;


ALTER FUNCTION public.wallets_wallets_after_insert_trigger_proc() OWNER TO agentyk;

--
-- Name: wallets_wallets_before_insert_trigger_proc(); Type: FUNCTION; Schema: public; Owner: agentyk
--

CREATE FUNCTION public.wallets_wallets_before_insert_trigger_proc() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	r RECORD;
BEGIN
	FOR r IN 
	  WITH RECURSIVE cte (wallet_id, parent_id, path, has_cycle) AS (
	  SELECT NEW.wallet_id, NEW.parent_id, ARRAY[NEW.parent_id]::TEXT[], NEW.wallet_id IS NOT DISTINCT FROM NEW.parent_id
	  UNION ALL
	  SELECT cte.parent_id, ww.wallet_id, cte.path || ww.wallet_id,  ww.wallet_id=ANY(cte.path) FROM cte
	  JOIN wallets_wallets ww ON ww.parent_id=cte.wallet_id
	  WHERE has_cycle IS FALSE)
	  SELECT 1 FROM cte WHERE has_cycle IS TRUE
	LOOP
	  RAISE EXCEPTION 'Cycle detected';
	END LOOP;
	RETURN NEW;
END;
$$;


ALTER FUNCTION public.wallets_wallets_before_insert_trigger_proc() OWNER TO agentyk;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: blks; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.blks (
    code text NOT NULL,
    blk_id text NOT NULL,
    height bigint,
    prev_id text,
    confirmed boolean DEFAULT false,
    indexed_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.blks OWNER TO agentyk;

--
-- Name: blks_txs; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.blks_txs (
    code text NOT NULL,
    blk_id text NOT NULL,
    tx_id text NOT NULL,
    blk_idx integer
);


ALTER TABLE public.blks_txs OWNER TO agentyk;

--
-- Name: descriptors; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.descriptors (
    code text NOT NULL,
    descriptor text NOT NULL,
    metadata jsonb,
    next_idx bigint DEFAULT 0,
    gap bigint DEFAULT 0
);


ALTER TABLE public.descriptors OWNER TO agentyk;

--
-- Name: descriptors_scripts; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.descriptors_scripts (
    code text NOT NULL,
    descriptor text NOT NULL,
    idx bigint NOT NULL,
    script text NOT NULL,
    metadata jsonb,
    used boolean DEFAULT false NOT NULL
);


ALTER TABLE public.descriptors_scripts OWNER TO agentyk;

--
-- Name: scripts; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.scripts (
    code text NOT NULL,
    script text NOT NULL,
    addr text NOT NULL,
    used boolean DEFAULT false NOT NULL
);


ALTER TABLE public.scripts OWNER TO agentyk;

--
-- Name: descriptors_scripts_unused; Type: VIEW; Schema: public; Owner: agentyk
--

CREATE VIEW public.descriptors_scripts_unused AS
 SELECT ds.code,
    ds.descriptor,
    ds.script,
    ds.idx,
    s.addr,
    d.metadata AS d_metadata,
    ds.metadata AS ds_metadata
   FROM ((public.descriptors_scripts ds
     JOIN public.scripts s USING (code, script))
     JOIN public.descriptors d USING (code, descriptor))
  WHERE (ds.used IS FALSE);


ALTER VIEW public.descriptors_scripts_unused OWNER TO agentyk;

--
-- Name: ins; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.ins (
    code text NOT NULL,
    tx_id text NOT NULL,
    idx bigint NOT NULL,
    spent_tx_id text NOT NULL,
    spent_idx bigint NOT NULL,
    script text NOT NULL,
    value bigint NOT NULL,
    asset_id text NOT NULL,
    blk_id text,
    blk_idx integer,
    blk_height bigint,
    mempool boolean DEFAULT true,
    replaced_by text,
    seen_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.ins OWNER TO agentyk;

--
-- Name: ins_outs; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.ins_outs (
    code text NOT NULL,
    tx_id text NOT NULL,
    idx bigint NOT NULL,
    is_out boolean NOT NULL,
    spent_tx_id text,
    spent_idx bigint,
    script text NOT NULL,
    value bigint NOT NULL,
    asset_id text NOT NULL,
    immature boolean,
    blk_id text,
    blk_idx integer,
    blk_height bigint,
    mempool boolean DEFAULT true,
    replaced_by text,
    seen_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.ins_outs OWNER TO agentyk;

--
-- Name: nbxv1_evts; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.nbxv1_evts (
    code text NOT NULL,
    id bigint NOT NULL,
    type text NOT NULL,
    data jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.nbxv1_evts OWNER TO agentyk;

--
-- Name: nbxv1_evts_ids; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.nbxv1_evts_ids (
    code text NOT NULL,
    curr_id bigint
);


ALTER TABLE public.nbxv1_evts_ids OWNER TO agentyk;

--
-- Name: wallets_descriptors; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.wallets_descriptors (
    code text NOT NULL,
    descriptor text NOT NULL,
    wallet_id text NOT NULL
);


ALTER TABLE public.wallets_descriptors OWNER TO agentyk;

--
-- Name: wallets_scripts; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.wallets_scripts (
    code text NOT NULL,
    script text NOT NULL,
    wallet_id text NOT NULL,
    ref_count integer DEFAULT 1
);


ALTER TABLE public.wallets_scripts OWNER TO agentyk;

--
-- Name: nbxv1_keypath_info; Type: VIEW; Schema: public; Owner: agentyk
--

CREATE VIEW public.nbxv1_keypath_info AS
 SELECT ws.code,
    ws.script,
    s.addr,
    d.metadata AS descriptor_metadata,
    public.nbxv1_get_keypath(d.metadata, ds.idx) AS keypath,
    ds.metadata AS descriptors_scripts_metadata,
    ws.wallet_id,
    ds.idx,
    ds.used,
    d.descriptor
   FROM ((public.wallets_scripts ws
     JOIN public.scripts s ON (((s.code = ws.code) AND (s.script = ws.script))))
     LEFT JOIN ((public.wallets_descriptors wd
     JOIN public.descriptors_scripts ds ON (((ds.code = wd.code) AND (ds.descriptor = wd.descriptor))))
     JOIN public.descriptors d ON (((d.code = ds.code) AND (d.descriptor = ds.descriptor)))) ON (((wd.wallet_id = ws.wallet_id) AND (wd.code = ws.code) AND (ds.script = ws.script))));


ALTER VIEW public.nbxv1_keypath_info OWNER TO agentyk;

--
-- Name: nbxv1_metadata; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.nbxv1_metadata (
    wallet_id text NOT NULL,
    key text NOT NULL,
    data jsonb
);


ALTER TABLE public.nbxv1_metadata OWNER TO agentyk;

--
-- Name: nbxv1_migrations; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.nbxv1_migrations (
    script_name text NOT NULL,
    executed_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.nbxv1_migrations OWNER TO agentyk;

--
-- Name: nbxv1_settings; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.nbxv1_settings (
    code text NOT NULL,
    key text NOT NULL,
    data_bytes bytea,
    data_json jsonb
);


ALTER TABLE public.nbxv1_settings OWNER TO agentyk;

--
-- Name: nbxv1_tracked_txs; Type: VIEW; Schema: public; Owner: agentyk
--

CREATE VIEW public.nbxv1_tracked_txs AS
 SELECT ws.wallet_id,
    io.code,
    io.tx_id,
    io.idx,
    io.is_out,
    io.spent_tx_id,
    io.spent_idx,
    io.script,
    io.value,
    io.asset_id,
    io.immature,
    io.blk_id,
    io.blk_idx,
    io.blk_height,
    io.mempool,
    io.replaced_by,
    io.seen_at,
    public.nbxv1_get_keypath(d.metadata, ds.idx) AS keypath,
    (d.metadata ->> 'feature'::text) AS feature,
    d.metadata AS descriptor_metadata,
    ds.idx AS key_idx
   FROM ((public.wallets_scripts ws
     JOIN public.ins_outs io ON (((io.code = ws.code) AND (io.script = ws.script))))
     LEFT JOIN ((public.wallets_descriptors wd
     JOIN public.descriptors_scripts ds ON (((ds.code = wd.code) AND (ds.descriptor = wd.descriptor))))
     JOIN public.descriptors d ON (((d.code = ds.code) AND (d.descriptor = ds.descriptor)))) ON (((wd.wallet_id = ws.wallet_id) AND (wd.code = ws.code) AND (ds.script = ws.script))))
  WHERE ((io.blk_id IS NOT NULL) OR (io.mempool IS TRUE));


ALTER VIEW public.nbxv1_tracked_txs OWNER TO agentyk;

--
-- Name: outs; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.outs (
    code text NOT NULL,
    tx_id text NOT NULL,
    idx bigint NOT NULL,
    script text NOT NULL,
    value bigint NOT NULL,
    asset_id text DEFAULT ''::text NOT NULL,
    input_tx_id text,
    input_idx bigint,
    input_mempool boolean DEFAULT false NOT NULL,
    immature boolean DEFAULT false NOT NULL,
    blk_id text,
    blk_idx integer,
    blk_height bigint,
    mempool boolean DEFAULT true,
    replaced_by text,
    seen_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.outs OWNER TO agentyk;

--
-- Name: spent_outs; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.spent_outs (
    code text NOT NULL,
    tx_id text NOT NULL,
    idx bigint NOT NULL,
    spent_by text NOT NULL,
    prev_spent_by text,
    spent_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.spent_outs OWNER TO agentyk;

--
-- Name: txs; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.txs (
    code text NOT NULL,
    tx_id text NOT NULL,
    raw bytea,
    metadata jsonb,
    immature boolean DEFAULT false,
    blk_id text,
    blk_idx integer,
    blk_height bigint,
    mempool boolean DEFAULT true,
    replaced_by text,
    seen_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.txs OWNER TO agentyk;

--
-- Name: utxos; Type: VIEW; Schema: public; Owner: agentyk
--

CREATE VIEW public.utxos AS
 SELECT code,
    tx_id,
    idx,
    script,
    value,
    asset_id,
    input_tx_id,
    input_idx,
    input_mempool,
    immature,
    blk_id,
    blk_idx,
    blk_height,
    mempool,
    replaced_by,
    seen_at
   FROM public.outs o
  WHERE (((blk_id IS NOT NULL) OR ((mempool IS TRUE) AND (replaced_by IS NULL))) AND ((input_tx_id IS NULL) OR (input_mempool IS TRUE)));


ALTER VIEW public.utxos OWNER TO agentyk;

--
-- Name: wallets; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.wallets (
    wallet_id text NOT NULL,
    metadata jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.wallets OWNER TO agentyk;

--
-- Name: wallets_utxos; Type: VIEW; Schema: public; Owner: agentyk
--

CREATE VIEW public.wallets_utxos AS
 SELECT q.wallet_id,
    u.code,
    u.tx_id,
    u.idx,
    u.script,
    u.value,
    u.asset_id,
    u.input_tx_id,
    u.input_idx,
    u.input_mempool,
    u.immature,
    u.blk_id,
    u.blk_idx,
    u.blk_height,
    u.mempool,
    u.replaced_by,
    u.seen_at
   FROM public.utxos u,
    LATERAL ( SELECT ws.wallet_id,
            ws.code,
            ws.script
           FROM public.wallets_scripts ws
          WHERE ((ws.code = u.code) AND (ws.script = u.script))) q;


ALTER VIEW public.wallets_utxos OWNER TO agentyk;

--
-- Name: wallets_balances; Type: VIEW; Schema: public; Owner: agentyk
--

CREATE VIEW public.wallets_balances AS
 SELECT wallet_id,
    code,
    asset_id,
    COALESCE(sum(value) FILTER (WHERE (input_mempool IS FALSE)), (0)::numeric) AS unconfirmed_balance,
    COALESCE(sum(value) FILTER (WHERE (blk_id IS NOT NULL)), (0)::numeric) AS confirmed_balance,
    COALESCE(sum(value) FILTER (WHERE ((input_mempool IS FALSE) AND (immature IS FALSE))), (0)::numeric) AS available_balance,
    COALESCE(sum(value) FILTER (WHERE (immature IS TRUE)), (0)::numeric) AS immature_balance
   FROM public.wallets_utxos
  GROUP BY wallet_id, code, asset_id;


ALTER VIEW public.wallets_balances OWNER TO agentyk;

--
-- Name: wallets_history; Type: MATERIALIZED VIEW; Schema: public; Owner: agentyk
--

CREATE MATERIALIZED VIEW public.wallets_history AS
 SELECT wallet_id,
    code,
    asset_id,
    tx_id,
    seen_at,
    blk_height,
    blk_idx,
    balance_change,
    sum(balance_change) OVER (PARTITION BY wallet_id, code, asset_id ORDER BY seen_at, blk_height, blk_idx) AS balance_total,
    rank() OVER (PARTITION BY wallet_id, code, asset_id ORDER BY seen_at, blk_height, blk_idx) AS nth
   FROM ( SELECT q_1.wallet_id,
            io.code,
            io.asset_id,
            min(io.blk_idx) AS blk_idx,
            min(io.blk_height) AS blk_height,
            io.tx_id,
            min(io.seen_at) AS seen_at,
            (COALESCE(sum(io.value) FILTER (WHERE (io.is_out IS TRUE)), (0)::numeric) - COALESCE(sum(io.value) FILTER (WHERE (io.is_out IS FALSE)), (0)::numeric)) AS balance_change
           FROM public.ins_outs io,
            LATERAL ( SELECT ts.wallet_id,
                    ts.code,
                    ts.script
                   FROM public.wallets_scripts ts
                  WHERE ((ts.code = io.code) AND (ts.script = io.script))) q_1
          WHERE (io.blk_id IS NOT NULL)
          GROUP BY q_1.wallet_id, io.code, io.asset_id, io.tx_id) q
  WITH NO DATA;


ALTER MATERIALIZED VIEW public.wallets_history OWNER TO agentyk;

--
-- Name: wallets_wallets; Type: TABLE; Schema: public; Owner: agentyk
--

CREATE TABLE public.wallets_wallets (
    wallet_id text NOT NULL,
    parent_id text NOT NULL
);


ALTER TABLE public.wallets_wallets OWNER TO agentyk;

--
-- Data for Name: blks; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.blks (code, blk_id, height, prev_id, confirmed, indexed_at) FROM stdin;
\.


--
-- Data for Name: blks_txs; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.blks_txs (code, blk_id, tx_id, blk_idx) FROM stdin;
\.


--
-- Data for Name: descriptors; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.descriptors (code, descriptor, metadata, next_idx, gap) FROM stdin;
\.


--
-- Data for Name: descriptors_scripts; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.descriptors_scripts (code, descriptor, idx, script, metadata, used) FROM stdin;
\.


--
-- Data for Name: ins; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.ins (code, tx_id, idx, spent_tx_id, spent_idx, script, value, asset_id, blk_id, blk_idx, blk_height, mempool, replaced_by, seen_at) FROM stdin;
\.


--
-- Data for Name: ins_outs; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.ins_outs (code, tx_id, idx, is_out, spent_tx_id, spent_idx, script, value, asset_id, immature, blk_id, blk_idx, blk_height, mempool, replaced_by, seen_at) FROM stdin;
\.


--
-- Data for Name: nbxv1_evts; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.nbxv1_evts (code, id, type, data, created_at) FROM stdin;
\.


--
-- Data for Name: nbxv1_evts_ids; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.nbxv1_evts_ids (code, curr_id) FROM stdin;
\.


--
-- Data for Name: nbxv1_metadata; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.nbxv1_metadata (wallet_id, key, data) FROM stdin;
\.


--
-- Data for Name: nbxv1_migrations; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.nbxv1_migrations (script_name, executed_at) FROM stdin;
001.Migrations	2026-03-07 18:46:17.11214+00
002.Model	2026-03-07 18:46:17.172107+00
003.Legacy	2026-03-07 18:46:17.35897+00
004.Fixup	2026-03-07 18:46:17.38927+00
005.ToBTCFix	2026-03-07 18:46:17.392773+00
006.GetWalletsRecent2	2026-03-07 18:46:17.394185+00
007.FasterSaveMatches	2026-03-07 18:46:17.396894+00
008.FasterGetUnused	2026-03-07 18:46:17.398607+00
009.FasterGetUnused2	2026-03-07 18:46:17.40357+00
010.ChangeEventsIdType	2026-03-07 18:46:17.40608+00
011.FixGetWalletsRecent	2026-03-07 18:46:17.422218+00
012.PerfFixGetWalletsRecent	2026-03-07 18:46:17.42477+00
013.FixTrackedTransactions	2026-03-07 18:46:17.426716+00
014.FixAddressReuse	2026-03-07 18:46:17.430341+00
015.AvoidWAL	2026-03-07 18:46:17.434147+00
016.FixTempTableCreation	2026-03-07 18:46:17.441385+00
017.FixDoubleSpendDetection	2026-03-07 18:46:17.443922+00
018.FastWalletRecent	2026-03-07 18:46:17.446415+00
019.FixDoubleSpendDetection2	2026-03-07 18:46:17.448408+00
020.ReplacingShouldBeIdempotent	2026-03-07 18:46:17.450335+00
021.KeyPathInfoReturnsWalletId	2026-03-07 18:46:17.453025+00
022.WalletsWalletsParentIdIndex	2026-03-07 18:46:17.456243+00
023.KeyPathInfoReturnsIndex	2026-03-07 18:46:17.460156+00
024.TrackedTxsReturnsFeature	2026-03-07 18:46:17.464191+00
025.TrackedTxReturnsDescriptorMetadata	2026-03-07 18:46:17.468982+00
\.


--
-- Data for Name: nbxv1_settings; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.nbxv1_settings (code, key, data_bytes, data_json) FROM stdin;
\.


--
-- Data for Name: outs; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.outs (code, tx_id, idx, script, value, asset_id, input_tx_id, input_idx, input_mempool, immature, blk_id, blk_idx, blk_height, mempool, replaced_by, seen_at) FROM stdin;
\.


--
-- Data for Name: scripts; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.scripts (code, script, addr, used) FROM stdin;
\.


--
-- Data for Name: spent_outs; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.spent_outs (code, tx_id, idx, spent_by, prev_spent_by, spent_at) FROM stdin;
\.


--
-- Data for Name: txs; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.txs (code, tx_id, raw, metadata, immature, blk_id, blk_idx, blk_height, mempool, replaced_by, seen_at) FROM stdin;
\.


--
-- Data for Name: wallets; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.wallets (wallet_id, metadata, created_at) FROM stdin;
\.


--
-- Data for Name: wallets_descriptors; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.wallets_descriptors (code, descriptor, wallet_id) FROM stdin;
\.


--
-- Data for Name: wallets_scripts; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.wallets_scripts (code, script, wallet_id, ref_count) FROM stdin;
\.


--
-- Data for Name: wallets_wallets; Type: TABLE DATA; Schema: public; Owner: agentyk
--

COPY public.wallets_wallets (wallet_id, parent_id) FROM stdin;
\.


--
-- Name: blks blks_pkey; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.blks
    ADD CONSTRAINT blks_pkey PRIMARY KEY (code, blk_id);


--
-- Name: blks_txs blks_txs_pkey; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.blks_txs
    ADD CONSTRAINT blks_txs_pkey PRIMARY KEY (code, tx_id, blk_id);


--
-- Name: descriptors descriptors_pkey; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.descriptors
    ADD CONSTRAINT descriptors_pkey PRIMARY KEY (code, descriptor);


--
-- Name: descriptors_scripts descriptors_scripts_pkey; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.descriptors_scripts
    ADD CONSTRAINT descriptors_scripts_pkey PRIMARY KEY (code, descriptor, idx) INCLUDE (script);


--
-- Name: ins_outs ins_outs_pkey; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.ins_outs
    ADD CONSTRAINT ins_outs_pkey PRIMARY KEY (code, tx_id, idx, is_out);


--
-- Name: ins ins_pkey; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.ins
    ADD CONSTRAINT ins_pkey PRIMARY KEY (code, tx_id, idx);


--
-- Name: nbxv1_evts_ids nbxv1_evts_ids_pkey; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.nbxv1_evts_ids
    ADD CONSTRAINT nbxv1_evts_ids_pkey PRIMARY KEY (code);


--
-- Name: nbxv1_evts nbxv1_evts_pkey; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.nbxv1_evts
    ADD CONSTRAINT nbxv1_evts_pkey PRIMARY KEY (code, id);


--
-- Name: nbxv1_metadata nbxv1_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.nbxv1_metadata
    ADD CONSTRAINT nbxv1_metadata_pkey PRIMARY KEY (wallet_id, key);


--
-- Name: nbxv1_migrations nbxv1_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.nbxv1_migrations
    ADD CONSTRAINT nbxv1_migrations_pkey PRIMARY KEY (script_name);


--
-- Name: nbxv1_settings nbxv1_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.nbxv1_settings
    ADD CONSTRAINT nbxv1_settings_pkey PRIMARY KEY (code, key);


--
-- Name: outs outs_pkey; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.outs
    ADD CONSTRAINT outs_pkey PRIMARY KEY (code, tx_id, idx) INCLUDE (script, value, asset_id);


--
-- Name: scripts scripts_pkey; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.scripts
    ADD CONSTRAINT scripts_pkey PRIMARY KEY (code, script);


--
-- Name: spent_outs spent_outs_pkey; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.spent_outs
    ADD CONSTRAINT spent_outs_pkey PRIMARY KEY (code, tx_id, idx);


--
-- Name: txs txs_pkey; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.txs
    ADD CONSTRAINT txs_pkey PRIMARY KEY (code, tx_id);


--
-- Name: wallets_descriptors wallets_descriptors_pkey; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.wallets_descriptors
    ADD CONSTRAINT wallets_descriptors_pkey PRIMARY KEY (code, descriptor, wallet_id);


--
-- Name: wallets wallets_pkey; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT wallets_pkey PRIMARY KEY (wallet_id);


--
-- Name: wallets_scripts wallets_scripts_pkey; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.wallets_scripts
    ADD CONSTRAINT wallets_scripts_pkey PRIMARY KEY (code, script, wallet_id);


--
-- Name: wallets_wallets wallets_wallets_pkey; Type: CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.wallets_wallets
    ADD CONSTRAINT wallets_wallets_pkey PRIMARY KEY (wallet_id, parent_id);


--
-- Name: blks_code_height_idx; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX blks_code_height_idx ON public.blks USING btree (code, height DESC) WHERE (confirmed IS TRUE);


--
-- Name: descriptors_scripts_code_script; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX descriptors_scripts_code_script ON public.descriptors_scripts USING btree (code, script);


--
-- Name: descriptors_scripts_unused_idx; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX descriptors_scripts_unused_idx ON public.descriptors_scripts USING btree (code, descriptor, idx) WHERE (used IS FALSE);


--
-- Name: ins_code_spentoutpoint_txid_idx; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX ins_code_spentoutpoint_txid_idx ON public.ins USING btree (code, spent_tx_id, spent_idx) INCLUDE (tx_id, idx);


--
-- Name: ins_outs_by_code_scripts_idx; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX ins_outs_by_code_scripts_idx ON public.ins_outs USING btree (code, script);


--
-- Name: ins_outs_seen_at_idx; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX ins_outs_seen_at_idx ON public.ins_outs USING btree (seen_at, blk_height, blk_idx);


--
-- Name: nbxv1_evts_code_id; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX nbxv1_evts_code_id ON public.nbxv1_evts USING btree (code, id DESC);


--
-- Name: nbxv1_evts_id; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX nbxv1_evts_id ON public.nbxv1_evts USING btree (id DESC);


--
-- Name: outs_unspent_idx; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX outs_unspent_idx ON public.outs USING btree (code) WHERE (((blk_id IS NOT NULL) OR ((mempool IS TRUE) AND (replaced_by IS NULL))) AND ((input_tx_id IS NULL) OR (input_mempool IS TRUE)));


--
-- Name: scripts_by_wallet_id_idx; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX scripts_by_wallet_id_idx ON public.wallets_scripts USING btree (wallet_id);


--
-- Name: txs_by_blk_id; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX txs_by_blk_id ON public.blks_txs USING btree (code, blk_id);


--
-- Name: txs_code_immature_idx; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX txs_code_immature_idx ON public.txs USING btree (code) INCLUDE (tx_id) WHERE (immature IS TRUE);


--
-- Name: txs_unconf_idx; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX txs_unconf_idx ON public.txs USING btree (code) INCLUDE (tx_id) WHERE (mempool IS TRUE);


--
-- Name: wallets_descriptors_by_wallet_id_idx; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX wallets_descriptors_by_wallet_id_idx ON public.wallets_descriptors USING btree (wallet_id);


--
-- Name: wallets_history_by_seen_at; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX wallets_history_by_seen_at ON public.wallets_history USING btree (seen_at);


--
-- Name: wallets_history_pk; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE UNIQUE INDEX wallets_history_pk ON public.wallets_history USING btree (wallet_id, code, asset_id, tx_id);


--
-- Name: wallets_wallets_parent_id; Type: INDEX; Schema: public; Owner: agentyk
--

CREATE INDEX wallets_wallets_parent_id ON public.wallets_wallets USING btree (parent_id);


--
-- Name: blks blks_confirmed_trigger; Type: TRIGGER; Schema: public; Owner: agentyk
--

CREATE TRIGGER blks_confirmed_trigger AFTER UPDATE ON public.blks FOR EACH ROW EXECUTE FUNCTION public.blks_confirmed_update_txs();


--
-- Name: blks_txs blks_txs_insert_trigger; Type: TRIGGER; Schema: public; Owner: agentyk
--

CREATE TRIGGER blks_txs_insert_trigger AFTER INSERT ON public.blks_txs FOR EACH ROW EXECUTE FUNCTION public.blks_txs_denormalize();


--
-- Name: descriptors_scripts descriptors_scripts_after_insert_or_update_trigger; Type: TRIGGER; Schema: public; Owner: agentyk
--

CREATE TRIGGER descriptors_scripts_after_insert_or_update_trigger BEFORE INSERT OR UPDATE ON public.descriptors_scripts FOR EACH ROW EXECUTE FUNCTION public.descriptors_scripts_after_insert_or_update_trigger_proc();


--
-- Name: descriptors_scripts descriptors_scripts_wallets_scripts_trigger; Type: TRIGGER; Schema: public; Owner: agentyk
--

CREATE TRIGGER descriptors_scripts_wallets_scripts_trigger AFTER INSERT ON public.descriptors_scripts REFERENCING NEW TABLE AS new_descriptors_scripts FOR EACH STATEMENT EXECUTE FUNCTION public.descriptors_scripts_wallets_scripts_trigger_proc();


--
-- Name: ins ins_after_insert2_trigger; Type: TRIGGER; Schema: public; Owner: agentyk
--

CREATE TRIGGER ins_after_insert2_trigger AFTER INSERT ON public.ins FOR EACH ROW EXECUTE FUNCTION public.ins_after_insert2_trigger_proc();


--
-- Name: ins ins_after_insert_trigger; Type: TRIGGER; Schema: public; Owner: agentyk
--

CREATE TRIGGER ins_after_insert_trigger AFTER INSERT ON public.ins REFERENCING NEW TABLE AS new_ins FOR EACH STATEMENT EXECUTE FUNCTION public.ins_after_insert_trigger_proc();


--
-- Name: ins ins_after_update_trigger; Type: TRIGGER; Schema: public; Owner: agentyk
--

CREATE TRIGGER ins_after_update_trigger BEFORE UPDATE ON public.ins FOR EACH ROW EXECUTE FUNCTION public.ins_after_update_trigger_proc();


--
-- Name: ins ins_before_insert_trigger; Type: TRIGGER; Schema: public; Owner: agentyk
--

CREATE TRIGGER ins_before_insert_trigger BEFORE INSERT ON public.ins FOR EACH ROW EXECUTE FUNCTION public.ins_before_insert_trigger_proc();


--
-- Name: ins ins_delete_trigger; Type: TRIGGER; Schema: public; Owner: agentyk
--

CREATE TRIGGER ins_delete_trigger BEFORE DELETE ON public.ins FOR EACH ROW EXECUTE FUNCTION public.ins_delete_ins_outs();


--
-- Name: outs outs_after_update_trigger; Type: TRIGGER; Schema: public; Owner: agentyk
--

CREATE TRIGGER outs_after_update_trigger AFTER UPDATE ON public.outs FOR EACH ROW EXECUTE FUNCTION public.outs_after_update_trigger_proc();


--
-- Name: outs outs_before_insert_trigger; Type: TRIGGER; Schema: public; Owner: agentyk
--

CREATE TRIGGER outs_before_insert_trigger BEFORE INSERT ON public.outs FOR EACH ROW EXECUTE FUNCTION public.outs_denormalize_from_tx();


--
-- Name: outs outs_delete_trigger; Type: TRIGGER; Schema: public; Owner: agentyk
--

CREATE TRIGGER outs_delete_trigger BEFORE DELETE ON public.outs FOR EACH ROW EXECUTE FUNCTION public.outs_delete_ins_outs();


--
-- Name: outs outs_insert_trigger; Type: TRIGGER; Schema: public; Owner: agentyk
--

CREATE TRIGGER outs_insert_trigger AFTER INSERT ON public.outs REFERENCING NEW TABLE AS new_outs FOR EACH STATEMENT EXECUTE FUNCTION public.outs_denormalize_to_ins_outs();


--
-- Name: scripts scripts_update_trigger; Type: TRIGGER; Schema: public; Owner: agentyk
--

CREATE TRIGGER scripts_update_trigger AFTER UPDATE ON public.scripts FOR EACH ROW EXECUTE FUNCTION public.scripts_set_descriptors_scripts_used();


--
-- Name: txs txs_insert_trigger; Type: TRIGGER; Schema: public; Owner: agentyk
--

CREATE TRIGGER txs_insert_trigger AFTER UPDATE ON public.txs FOR EACH ROW EXECUTE FUNCTION public.txs_denormalize();


--
-- Name: wallets_descriptors wallets_descriptors_after_delete_trigger; Type: TRIGGER; Schema: public; Owner: agentyk
--

CREATE TRIGGER wallets_descriptors_after_delete_trigger AFTER DELETE ON public.wallets_descriptors REFERENCING OLD TABLE AS new_wallets_descriptors FOR EACH STATEMENT EXECUTE FUNCTION public.wallets_descriptors_after_delete_trigger_proc();


--
-- Name: wallets_descriptors wallets_descriptors_after_insert_trigger; Type: TRIGGER; Schema: public; Owner: agentyk
--

CREATE TRIGGER wallets_descriptors_after_insert_trigger AFTER INSERT ON public.wallets_descriptors REFERENCING NEW TABLE AS new_wallets_descriptors FOR EACH STATEMENT EXECUTE FUNCTION public.wallets_descriptors_after_insert_trigger_proc();


--
-- Name: wallets_scripts wallets_scripts_after_delete_trigger; Type: TRIGGER; Schema: public; Owner: agentyk
--

CREATE TRIGGER wallets_scripts_after_delete_trigger AFTER DELETE ON public.wallets_scripts REFERENCING OLD TABLE AS new_wallets_scripts FOR EACH STATEMENT EXECUTE FUNCTION public.wallets_scripts_after_delete_trigger_proc();


--
-- Name: wallets_scripts wallets_scripts_after_insert_trigger; Type: TRIGGER; Schema: public; Owner: agentyk
--

CREATE TRIGGER wallets_scripts_after_insert_trigger AFTER INSERT ON public.wallets_scripts REFERENCING NEW TABLE AS new_wallets_scripts FOR EACH STATEMENT EXECUTE FUNCTION public.wallets_scripts_after_insert_trigger_proc();


--
-- Name: wallets_scripts wallets_scripts_after_update_trigger; Type: TRIGGER; Schema: public; Owner: agentyk
--

CREATE TRIGGER wallets_scripts_after_update_trigger AFTER UPDATE ON public.wallets_scripts REFERENCING NEW TABLE AS new_wallets_scripts FOR EACH STATEMENT EXECUTE FUNCTION public.wallets_scripts_after_update_trigger_proc();


--
-- Name: wallets_wallets wallets_wallets_after_delete_trigger; Type: TRIGGER; Schema: public; Owner: agentyk
--

CREATE TRIGGER wallets_wallets_after_delete_trigger AFTER DELETE ON public.wallets_wallets REFERENCING OLD TABLE AS new_wallets_wallets FOR EACH STATEMENT EXECUTE FUNCTION public.wallets_wallets_after_delete_trigger_proc();


--
-- Name: wallets_wallets wallets_wallets_after_insert_trigger; Type: TRIGGER; Schema: public; Owner: agentyk
--

CREATE TRIGGER wallets_wallets_after_insert_trigger AFTER INSERT ON public.wallets_wallets REFERENCING NEW TABLE AS new_wallets_wallets FOR EACH STATEMENT EXECUTE FUNCTION public.wallets_wallets_after_insert_trigger_proc();


--
-- Name: wallets_wallets wallets_wallets_before_insert_trigger; Type: TRIGGER; Schema: public; Owner: agentyk
--

CREATE TRIGGER wallets_wallets_before_insert_trigger BEFORE INSERT ON public.wallets_wallets FOR EACH ROW EXECUTE FUNCTION public.wallets_wallets_before_insert_trigger_proc();


--
-- Name: blks_txs blks_txs_code_blk_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.blks_txs
    ADD CONSTRAINT blks_txs_code_blk_id_fkey FOREIGN KEY (code, blk_id) REFERENCES public.blks(code, blk_id) ON DELETE CASCADE;


--
-- Name: blks_txs blks_txs_code_tx_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.blks_txs
    ADD CONSTRAINT blks_txs_code_tx_id_fkey FOREIGN KEY (code, tx_id) REFERENCES public.txs(code, tx_id) ON DELETE CASCADE;


--
-- Name: descriptors_scripts descriptors_scripts_code_script_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.descriptors_scripts
    ADD CONSTRAINT descriptors_scripts_code_script_fkey FOREIGN KEY (code, script) REFERENCES public.scripts(code, script) ON DELETE CASCADE;


--
-- Name: ins ins_code_script_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.ins
    ADD CONSTRAINT ins_code_script_fkey FOREIGN KEY (code, script) REFERENCES public.scripts(code, script) ON DELETE CASCADE;


--
-- Name: ins ins_code_spent_tx_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.ins
    ADD CONSTRAINT ins_code_spent_tx_id_fkey FOREIGN KEY (code, spent_tx_id) REFERENCES public.txs(code, tx_id) ON DELETE CASCADE;


--
-- Name: ins ins_code_spent_tx_id_spent_idx_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.ins
    ADD CONSTRAINT ins_code_spent_tx_id_spent_idx_fkey FOREIGN KEY (code, spent_tx_id, spent_idx) REFERENCES public.outs(code, tx_id, idx) ON DELETE CASCADE;


--
-- Name: ins ins_code_tx_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.ins
    ADD CONSTRAINT ins_code_tx_id_fkey FOREIGN KEY (code, tx_id) REFERENCES public.txs(code, tx_id) ON DELETE CASCADE;


--
-- Name: ins_outs ins_outs_code_spent_tx_id_spent_idx_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.ins_outs
    ADD CONSTRAINT ins_outs_code_spent_tx_id_spent_idx_fkey FOREIGN KEY (code, spent_tx_id, spent_idx) REFERENCES public.outs(code, tx_id, idx);


--
-- Name: nbxv1_metadata nbxv1_metadata_wallet_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.nbxv1_metadata
    ADD CONSTRAINT nbxv1_metadata_wallet_id_fkey FOREIGN KEY (wallet_id) REFERENCES public.wallets(wallet_id) ON DELETE CASCADE;


--
-- Name: outs outs_code_script_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.outs
    ADD CONSTRAINT outs_code_script_fkey FOREIGN KEY (code, script) REFERENCES public.scripts(code, script) ON DELETE CASCADE;


--
-- Name: outs outs_code_tx_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.outs
    ADD CONSTRAINT outs_code_tx_id_fkey FOREIGN KEY (code, tx_id) REFERENCES public.txs(code, tx_id) ON DELETE CASCADE;


--
-- Name: outs outs_spent_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.outs
    ADD CONSTRAINT outs_spent_by_fk FOREIGN KEY (code, input_tx_id, input_idx) REFERENCES public.ins(code, tx_id, idx) ON DELETE SET NULL;


--
-- Name: spent_outs spent_outs_code_prev_spent_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.spent_outs
    ADD CONSTRAINT spent_outs_code_prev_spent_by_fkey FOREIGN KEY (code, prev_spent_by) REFERENCES public.txs(code, tx_id) ON DELETE CASCADE;


--
-- Name: spent_outs spent_outs_code_spent_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.spent_outs
    ADD CONSTRAINT spent_outs_code_spent_by_fkey FOREIGN KEY (code, spent_by) REFERENCES public.txs(code, tx_id) ON DELETE CASCADE;


--
-- Name: txs txs_code_blk_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.txs
    ADD CONSTRAINT txs_code_blk_id_fkey FOREIGN KEY (code, blk_id) REFERENCES public.blks(code, blk_id) ON DELETE SET NULL;


--
-- Name: wallets_descriptors wallets_descriptors_code_descriptor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.wallets_descriptors
    ADD CONSTRAINT wallets_descriptors_code_descriptor_fkey FOREIGN KEY (code, descriptor) REFERENCES public.descriptors(code, descriptor) ON DELETE CASCADE;


--
-- Name: wallets_descriptors wallets_descriptors_wallet_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.wallets_descriptors
    ADD CONSTRAINT wallets_descriptors_wallet_id_fkey FOREIGN KEY (wallet_id) REFERENCES public.wallets(wallet_id) ON DELETE CASCADE;


--
-- Name: wallets_scripts wallets_scripts_code_script_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.wallets_scripts
    ADD CONSTRAINT wallets_scripts_code_script_fkey FOREIGN KEY (code, script) REFERENCES public.scripts(code, script) ON DELETE CASCADE;


--
-- Name: wallets_scripts wallets_scripts_wallet_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.wallets_scripts
    ADD CONSTRAINT wallets_scripts_wallet_id_fkey FOREIGN KEY (wallet_id) REFERENCES public.wallets(wallet_id) ON DELETE CASCADE;


--
-- Name: wallets_wallets wallets_wallets_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.wallets_wallets
    ADD CONSTRAINT wallets_wallets_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.wallets(wallet_id) ON DELETE CASCADE;


--
-- Name: wallets_wallets wallets_wallets_wallet_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: agentyk
--

ALTER TABLE ONLY public.wallets_wallets
    ADD CONSTRAINT wallets_wallets_wallet_id_fkey FOREIGN KEY (wallet_id) REFERENCES public.wallets(wallet_id) ON DELETE CASCADE;


--
-- Name: wallets_history; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: agentyk
--

REFRESH MATERIALIZED VIEW public.wallets_history;


--
-- PostgreSQL database dump complete
--

\unrestrict XL2amhRKrxbzBPIQJAUyLe6ewvyrv79h5o9wIunQACDRugm0cdJBq5m2YpvxFLC

--
-- Database "postgres" dump
--

\connect postgres

--
-- PostgreSQL database dump
--

\restrict doBa5kQkIg6N848fhaaOdvHaGTEVPdxJvUOuz7f5vWDdcVweLSVM1efXVmJcmpr

-- Dumped from database version 16.13
-- Dumped by pg_dump version 16.13

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- PostgreSQL database dump complete
--

\unrestrict doBa5kQkIg6N848fhaaOdvHaGTEVPdxJvUOuz7f5vWDdcVweLSVM1efXVmJcmpr

--
-- PostgreSQL database cluster dump complete
--

