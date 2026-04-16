-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  069: AI Usage Logging & Cost Tracking                                 ║
-- ║  Tracks all AI proxy calls for cost monitoring and budget enforcement  ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

CREATE TABLE IF NOT EXISTS ai_usage_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  tokens_used INTEGER NOT NULL DEFAULT 0,
  model TEXT NOT NULL DEFAULT 'gpt-4o-mini',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for per-user daily budget queries
CREATE INDEX idx_ai_usage_user_date ON ai_usage_logs (user_id, created_at DESC);

-- Index for cost monitoring dashboards
CREATE INDEX idx_ai_usage_model_date ON ai_usage_logs (model, created_at DESC);

-- RLS: Users can only read their own usage
ALTER TABLE ai_usage_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own AI usage"
  ON ai_usage_logs FOR SELECT
  USING (auth.uid() = user_id);

-- Service role can insert (edge functions)
CREATE POLICY "Service role inserts AI usage"
  ON ai_usage_logs FOR INSERT
  WITH CHECK (true);

-- Materialized view for daily cost summary (refresh via cron)
CREATE OR REPLACE VIEW ai_daily_costs AS
SELECT
  date_trunc('day', created_at) AS day,
  model,
  COUNT(*) AS total_calls,
  SUM(tokens_used) AS total_tokens,
  CASE model
    WHEN 'gpt-4o-mini' THEN SUM(tokens_used) * 0.00000015
    WHEN 'gpt-4o' THEN SUM(tokens_used) * 0.000005
    WHEN 'gpt-4-turbo' THEN SUM(tokens_used) * 0.00001
    ELSE SUM(tokens_used) * 0.0000005
  END AS estimated_cost_usd
FROM ai_usage_logs
GROUP BY date_trunc('day', created_at), model
ORDER BY day DESC;
