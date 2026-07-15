# 🔍 Parameter Audit Report — roadfx.biz.id & Cloud Run ai-vitality

**Date:** 2026-07-15
**Status:** Partially fixed from sandbox, some require manual action

---

## ✅ FIXED (via API from sandbox)

### 1. Clerk Allowed Origins — FIXED
- **Before:** `null` (no domains whitelisted)
- **After:** 21 domains added
- Clerk auth now works on all roadfx.biz.id subdomains

### 2. Domain Mapping — FIXED
- 14 subdomains mapped to Cloudflare Workers via Workers Domains API
- All responding HTTP 200 with HTTPS

---

## ❌ NEEDS MANUAL FIX (cannot do from sandbox)

### 1. CLERK_SECRET_KEY in Cloud Run — WRONG VALUE
```
Current:  CLERK_SECRET_KEY = pk_test_YXdha2UtY2hpY2tlbi05NS5jbGVyay5hY2NvdW50cy5kZXYk  (PUBLIC KEY!)
Should be: CLERK_SECRET_KEY = sk_test_0DUF4QTu4UJIvmhoWoaucpVO2tCWxyjMyEGgYogAUD  (SECRET KEY)
```
**This is the same as CLERK_SK** — someone put the public key where the secret key should be.

**Fix:**
1. Open https://console.cloud.google.com/run?project=yttriferous-magpie-16ppv
2. Click **ai-vitality** service
3. Click **"Edit & Deploy New Revision"**
4. Click the **container** to edit
5. Find `CLERK_SECRET_KEY` env var
6. Change value from `pk_test_YXdha2UtY2hpY2tlbi05NS5jbGVyay5hY2NvdW50cy5kZXYk` to `sk_test_0DUF4QTu4UJIvmhoWoaucpVO2tCWxyjMyEGgYogAUD`
7. Click **Deploy**

### 2. Duplicate/Redundant Env Vars
| Variable | Issue | Action |
|----------|-------|--------|
| GEMINI_KEY = GEMINI_API_KEY | Same value | Remove one |
| OR_KEY = OR_PROV_KEY | Same value | Remove one |
| MONGO_URI = MONGODB_URI | Same value | Remove one |
| CF_AI_TOKEN ≠ CF_TOKEN | Different values | Keep both, verify which is active |

### 3. SOLACE_API_TOKEN — Truncated
```
Current: eyJhbGciOiJSUzI1NiIs  (only ~20 chars, should be longer)
```
Needs full JWT token.

---

## ⚠️ WARNINGS (not critical but should fix)

### 4. Cloud Run APP_URL
```
Current: https://ai-vitality-819208434965.us-west1.run.app
Should add: https://roadfx.biz.id
```

### 5. certveis.space Nameservers
```
Current: Not pointed to Cloudflare (resolves to 2.57.91.92)
Should be: paris.ns.cloudflare.com + vern.ns.cloudflare.com
```
All certveis.space subdomains will work once NS is fixed.

---

## 📊 Full Parameter Status

| Category | Total | ✅ OK | ❌ Broken | ⚠️ Warning |
|----------|-------|-------|-----------|-------------|
| Clerk Auth | 3 keys | 2 | 1 (CLERK_SECRET_KEY) | 0 |
| AI Keys | 9 keys | 9 | 0 | 3 (duplicates) |
| Database | 3 vars | 3 | 0 | 1 (duplicate) |
| Solace | 4 vars | 3 | 0 | 1 (truncated) |
| Cloudflare | 3 vars | 3 | 0 | 0 |
| App Config | 3 vars | 3 | 0 | 0 |
| Misc Keys | 6 vars | 6 | 0 | 0 |
| **TOTAL** | **31** | **29** | **1** | **5** |

---

## 🔧 Quick Fix Commands (run in GCP Console)

```bash
# Update Cloud Run env vars (fix CLERK_SECRET_KEY)
gcloud run services update ai-vitality \
  --region us-west1 \
  --project yttriferous-magpie-16ppv \
  --update-env-vars "CLERK_SECRET_KEY=sk_test_0DUF4QTu4UJIvmhoWoaucpVO2tCWxyjMyEGgYogAUD" \
  --update-env-vars "APP_URL=https://roadfx.biz.id"
```
