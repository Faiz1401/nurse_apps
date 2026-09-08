-- ============================================================================
-- Module 5 — Nurse Verification
-- Table: nurse_documents
-- Storage: private bucket `nurse-documents`, path convention
--   {nurse_id}/{doc_type}_{timestamp}.{ext}
--
-- Verification decisions (approve/reject a document, or set a nurse's
-- overall verification_status) are admin-only actions, enforced by a
-- trigger below — not just RLS — so a nurse can never self-approve by
-- crafting a payload that includes status/reviewed_by/reviewed_at.
--
-- Deferred: automated document-expiry push/email notifications need the
-- Notifications foundation (Phase 1 roadmap step 14) and a scheduled Edge
-- Function (nightly-doc-expiry-check, see docs/06-api-design.md) — neither
-- exists yet. This module surfaces expiry visually in the admin UI only.
-- ============================================================================

create table nurse_documents (
  id uuid primary key default gen_random_uuid(),
  nurse_id uuid not null references nurses(id) on delete cascade,
  doc_type text not null check (
    doc_type in ('ic','qualification','apc','certificate','experience_letter','photo','bank_proof','other')
  ),
  file_url text not null,
  status verification_status not null default 'pending',
  expiry_date date,
  reviewed_by uuid references profiles(id),
  reviewed_at timestamptz,
  notes text,
  created_at timestamptz not null default now()
);
create index idx_nurse_documents_nurse on nurse_documents(nurse_id);
create index idx_nurse_documents_expiry on nurse_documents(expiry_date) where expiry_date is not null;

-- ----------------------------------------------------------------------------
-- Guard: only an admin's insert/update can ever set status/reviewed_by/
-- reviewed_at to something other than the safe default — a nurse uploading
-- or re-uploading a document always lands on 'pending' with no reviewer.
-- ----------------------------------------------------------------------------
create or replace function guard_nurse_document_review_fields()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not is_admin() then
    if tg_op = 'INSERT' then
      new.status := 'pending';
      new.reviewed_by := null;
      new.reviewed_at := null;
    elsif tg_op = 'UPDATE' then
      new.status := old.status;
      new.reviewed_by := old.reviewed_by;
      new.reviewed_at := old.reviewed_at;
    end if;
  end if;
  return new;
end;
$$;

create trigger trg_guard_nurse_document_review
  before insert or update on nurse_documents
  for each row execute function guard_nurse_document_review_fields();

alter table nurse_documents enable row level security;

create policy nurse_documents_select_owner_or_admin on nurse_documents
  for select using (nurse_id = auth.uid() or is_admin());

create policy nurse_documents_insert_owner_or_admin on nurse_documents
  for insert with check (nurse_id = auth.uid() or is_admin());

create policy nurse_documents_update_owner_or_admin on nurse_documents
  for update using (nurse_id = auth.uid() or is_admin());

-- No delete for the nurse themselves — documents stay as a review history
-- even after rejection; only admins can remove one (e.g. duplicates/junk).
create policy nurse_documents_delete_admin_only on nurse_documents
  for delete using (is_admin());

create trigger trg_audit_nurse_documents
  after insert or update or delete on nurse_documents
  for each row execute function log_audit();

-- ----------------------------------------------------------------------------
-- Storage bucket + policies. Private bucket — files are only ever reachable
-- via short-lived signed URLs generated for an authorized viewer, never a
-- public URL.
-- ----------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('nurse-documents', 'nurse-documents', false)
on conflict (id) do nothing;

create policy nurse_documents_storage_select on storage.objects
  for select using (
    bucket_id = 'nurse-documents'
    and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin())
  );

create policy nurse_documents_storage_insert on storage.objects
  for insert with check (
    bucket_id = 'nurse-documents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy nurse_documents_storage_delete on storage.objects
  for delete using (
    bucket_id = 'nurse-documents'
    and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin())
  );
