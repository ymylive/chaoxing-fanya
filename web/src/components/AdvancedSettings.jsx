import React, { useState } from 'react';
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from './ui/Card';
import Input from './ui/Input';
import Label from './ui/Label';
import { Settings2, Database, Bell, Eye } from 'lucide-react';

const AdvancedSettings = ({ settings, onChange }) => {
  const [showAdvanced, setShowAdvanced] = useState(false);

  const handleTikuChange = (field, value) => {
    onChange({
      ...settings,
      tiku_config: {
        ...settings.tiku_config,
        [field]: value,
      },
    });
  };

  const handleNotificationChange = (field, value) => {
    onChange({
      ...settings,
      notification_config: {
        ...settings.notification_config,
        [field]: value,
      },
    });
  };

  const handleOcrChange = (field, value) => {
    onChange({
      ...settings,
      ocr_config: {
        ...(settings.ocr_config || {}),
        [field]: value,
      },
    });
  };

  return (
    <div className="space-y-4">
      <button
        type="button"
        onClick={() => setShowAdvanced(!showAdvanced)}
        className="flex items-center text-sm text-primary hover:text-primary/80 font-medium"
      >
        <Settings2 className="mr-2 h-4 w-4" />
        {showAdvanced ? '隐藏高级配置' : '显示高级配置'}
      </button>

      {showAdvanced && (
        <>
          {/* 题库配置 */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center text-lg">
                <Database className="mr-2 h-5 w-5" />
                题库配置
              </CardTitle>
              <CardDescription>
                配置题库用于章节检测自动答题（可选）
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="tiku-provider">题库提供商</Label>
                <select
                  id="tiku-provider"
                  className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                  value={settings.tiku_config?.provider || ''}
                  onChange={(e) => handleTikuChange('provider', e.target.value)}
                >
                  <option value="">不使用题库</option>
                  <option value="TikuYanxi">言溪题库</option>
                  <option value="TikuLike">LIKE知识库</option>
                  <option value="TikuAdapter">TikuAdapter</option>
                  <option value="AI">AI大模型</option>
                  <option value="SiliconFlow">硅基流动AI</option>
                </select>
              </div>

              {settings.tiku_config?.provider && (
                <>
                  <div className="space-y-2">
                    <Label htmlFor="tiku-tokens">Token</Label>
                    <Input
                      id="tiku-tokens"
                      type="text"
                      placeholder="多个token用逗号分隔"
                      value={settings.tiku_config?.tokens || ''}
                      onChange={(e) => handleTikuChange('tokens', e.target.value)}
                    />
                    <p className="text-xs text-muted-foreground">
                      言溪题库或LIKE知识库的Token
                    </p>
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="tiku-submit">自动提交答题</Label>
                    <select
                      id="tiku-submit"
                      className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                      value={settings.tiku_config?.submit || 'false'}
                      onChange={(e) => handleTikuChange('submit', e.target.value)}
                    >
                      <option value="false">仅保存，不提交</option>
                      <option value="true">达到覆盖率自动提交</option>
                    </select>
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="tiku-cover-rate">最低题库覆盖率</Label>
                    <Input
                      id="tiku-cover-rate"
                      type="number"
                      min="0"
                      max="1"
                      step="0.1"
                      value={settings.tiku_config?.cover_rate || 0.9}
                      onChange={(e) => handleTikuChange('cover_rate', parseFloat(e.target.value))}
                    />
                    <p className="text-xs text-muted-foreground">
                      范围: 0.0 - 1.0，推荐0.9
                    </p>
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="tiku-delay">查询延迟（秒）</Label>
                    <Input
                      id="tiku-delay"
                      type="number"
                      min="0"
                      step="0.5"
                      value={settings.tiku_config?.delay || 1.0}
                      onChange={(e) => handleTikuChange('delay', parseFloat(e.target.value))}
                    />
                    <p className="text-xs text-muted-foreground">
                      题库查询间隔时间
                    </p>
                  </div>

                  {/* AI配置 */}
                  {(settings.tiku_config?.provider === 'AI' || settings.tiku_config?.provider === 'SiliconFlow') && (
                    <>
                      <div className="space-y-2">
                        <Label htmlFor="ai-endpoint">API Endpoint</Label>
                        <Input
                          id="ai-endpoint"
                          type="text"
                          placeholder="https://api.example.com/v1"
                          value={settings.tiku_config?.endpoint || ''}
                          onChange={(e) => handleTikuChange('endpoint', e.target.value)}
                        />
                      </div>

                      <div className="space-y-2">
                        <Label htmlFor="ai-key">API Key</Label>
                        <Input
                          id="ai-key"
                          type="password"
                          placeholder="your-api-key"
                          value={settings.tiku_config?.key || ''}
                          onChange={(e) => handleTikuChange('key', e.target.value)}
                        />
                      </div>

                      <div className="space-y-2">
                        <Label htmlFor="ai-model">模型名称</Label>
                        <Input
                          id="ai-model"
                          type="text"
                          placeholder="gpt-3.5-turbo"
                          value={settings.tiku_config?.model || ''}
                          onChange={(e) => handleTikuChange('model', e.target.value)}
                        />
                      </div>

                      <div className="space-y-2">
                        <Label htmlFor="ai-min-interval">请求最小间隔（秒）</Label>
                        <Input
                          id="ai-min-interval"
                          type="number"
                          min="0"
                          step="0.1"
                          value={
                            typeof settings.tiku_config?.min_interval_seconds === 'number'
                              ? settings.tiku_config.min_interval_seconds
                              : 3
                          }
                          onChange={(e) =>
                            handleTikuChange('min_interval_seconds', parseFloat(e.target.value) || 0)
                          }
                        />
                      </div>

                      <div className="space-y-2">
                        <Label htmlFor="ai-concurrency">单卷最大并发题目数</Label>
                        <Input
                          id="ai-concurrency"
                          type="number"
                          min="1"
                          max="10"
                          step="1"
                          value={settings.tiku_config?.ai_concurrency || 3}
                          onChange={(e) =>
                            handleTikuChange('ai_concurrency', parseInt(e.target.value, 10) || 1)
                          }
                        />
                      </div>
                    </>
                  )}

                  {/* TikuAdapter配置 */}
                  {settings.tiku_config?.provider === 'TikuAdapter' && (
                    <div className="space-y-2">
                      <Label htmlFor="adapter-url">TikuAdapter URL</Label>
                      <Input
                        id="adapter-url"
                        type="text"
                        placeholder="http://localhost:8080"
                        value={settings.tiku_config?.url || ''}
                        onChange={(e) => handleTikuChange('url', e.target.value)}
                      />
                    </div>
                  )}
                </>
              )}
            </CardContent>
          </Card>

          {/* 通知配置 */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center text-lg">
                <Bell className="mr-2 h-5 w-5" />
                外部通知配置
              </CardTitle>
              <CardDescription>
                任务完成或出错时推送通知（可选）
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="notification-provider">通知服务</Label>
                <select
                  id="notification-provider"
                  className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                  value={settings.notification_config?.provider || ''}
                  onChange={(e) => handleNotificationChange('provider', e.target.value)}
                >
                  <option value="">不使用通知</option>
                  <option value="ServerChan">Server酱</option>
                  <option value="Qmsg">Qmsg酱</option>
                  <option value="Bark">Bark</option>
                  <option value="Telegram">Telegram</option>
                </select>
              </div>

              {settings.notification_config?.provider && (
                <>
                  <div className="space-y-2">
                    <Label htmlFor="notification-url">通知URL</Label>
                    <Input
                      id="notification-url"
                      type="text"
                      placeholder="https://..."
                      value={settings.notification_config?.url || ''}
                      onChange={(e) => handleNotificationChange('url', e.target.value)}
                    />
                    <p className="text-xs text-muted-foreground">
                      {settings.notification_config?.provider === 'ServerChan' && 'https://sctapi.ftqq.com/YOUR_KEY.send'}
                      {settings.notification_config?.provider === 'Qmsg' && 'https://qmsg.zendee.cn/send/YOUR_KEY'}
                      {settings.notification_config?.provider === 'Bark' && 'https://api.day.app/YOUR_KEY/'}
                      {settings.notification_config?.provider === 'Telegram' && 'https://api.telegram.org/botYOUR_TOKEN/sendMessage'}
                    </p>
                  </div>

                  {settings.notification_config?.provider === 'Telegram' && (
                    <div className="space-y-2">
                      <Label htmlFor="tg-chat-id">Chat ID</Label>
                      <Input
                        id="tg-chat-id"
                        type="text"
                        placeholder="123456789"
                        value={settings.notification_config?.tg_chat_id || ''}
                        onChange={(e) => handleNotificationChange('tg_chat_id', e.target.value)}
                      />
                    </div>
                  )}
                </>
              )}
            </CardContent>
          </Card>

          {/* 图片 OCR 配置 */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center text-lg">
                <Eye className="mr-2 h-5 w-5" />
                图片 OCR 配置
              </CardTitle>
              <CardDescription>
                配置 AI 视觉模型识别题目图片中的文字/公式（可选）
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="ocr-provider">OCR 提供商</Label>
                <select
                  id="ocr-provider"
                  className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                  value={settings.ocr_config?.provider || ''}
                  onChange={(e) => handleOcrChange('provider', e.target.value)}
                >
                  <option value="">不使用图片 OCR</option>
                  <option value="openai">OpenAI (GPT-4o)</option>
                  <option value="claude">Claude 3 (Anthropic)</option>
                  <option value="qwen">通义千问 VL</option>
                  <option value="siliconflow">硅基流动 (推荐国内)</option>
                  <option value="openai_compatible">OpenAI 兼容 API</option>
                </select>
                <p className="text-xs text-muted-foreground">
                  用于识别题目中的图片（如数学公式），提升答题准确率
                </p>
              </div>

              {settings.ocr_config?.provider && (
                <>
                  <div className="space-y-2">
                    <Label htmlFor="ocr-key">API Key</Label>
                    <Input
                      id="ocr-key"
                      type="password"
                      placeholder="sk-..."
                      value={settings.ocr_config?.key || ''}
                      onChange={(e) => handleOcrChange('key', e.target.value)}
                    />
                    <p className="text-xs text-muted-foreground">
                      {settings.ocr_config?.provider === 'siliconflow' && '硅基流动 API Key，可在 siliconflow.cn 获取'}
                      {settings.ocr_config?.provider === 'openai' && 'OpenAI API Key'}
                      {settings.ocr_config?.provider === 'claude' && 'Anthropic API Key'}
                      {settings.ocr_config?.provider === 'qwen' && '阿里云 DashScope API Key'}
                      {settings.ocr_config?.provider === 'openai_compatible' && '兼容 API 的密钥'}
                    </p>
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="ocr-endpoint">API 端点（可选）</Label>
                    <Input
                      id="ocr-endpoint"
                      type="text"
                      placeholder={
                        settings.ocr_config?.provider === 'openai' ? 'https://api.openai.com/v1/chat/completions' :
                        settings.ocr_config?.provider === 'claude' ? 'https://api.anthropic.com/v1/messages' :
                        settings.ocr_config?.provider === 'qwen' ? 'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions' :
                        settings.ocr_config?.provider === 'siliconflow' ? 'https://api.siliconflow.cn/v1/chat/completions' :
                        'https://your-api-endpoint/v1/chat/completions'
                      }
                      value={settings.ocr_config?.endpoint || ''}
                      onChange={(e) => handleOcrChange('endpoint', e.target.value)}
                    />
                    <p className="text-xs text-muted-foreground">
                      留空使用默认端点，自定义端点需填写完整 URL
                    </p>
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="ocr-model">模型名称（可选）</Label>
                    <Input
                      id="ocr-model"
                      type="text"
                      placeholder={
                        settings.ocr_config?.provider === 'openai' ? 'gpt-4o' :
                        settings.ocr_config?.provider === 'claude' ? 'claude-3-5-sonnet-20241022' :
                        settings.ocr_config?.provider === 'qwen' ? 'qwen-vl-plus' :
                        settings.ocr_config?.provider === 'siliconflow' ? 'Qwen/Qwen2-VL-72B-Instruct' :
                        'gpt-4o'
                      }
                      value={settings.ocr_config?.model || ''}
                      onChange={(e) => handleOcrChange('model', e.target.value)}
                    />
                    <p className="text-xs text-muted-foreground">
                      留空使用默认模型
                    </p>
                  </div>
                </>
              )}
            </CardContent>
          </Card>
        </>
      )}
    </div>
  );
};

export default AdvancedSettings;
