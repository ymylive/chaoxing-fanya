import React, { useState, useEffect } from 'react';
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from './ui/Card';
import Button from './ui/Button';
import Input from './ui/Input';
import Label from './ui/Label';
import { Play, Loader2, BookOpen, Settings, LogOut } from 'lucide-react';
import api from '../api/axios';
import AdvancedSettings from './AdvancedSettings';

const CourseSelection = ({ userInfo, onStartStudy, onLogout }) => {
  const [courses, setCourses] = useState([]);
  const [selectedCourses, setSelectedCourses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showSettings, setShowSettings] = useState(false);
  const [saving, setSaving] = useState(false);
  const [saveStatus, setSaveStatus] = useState('');
  const [settings, setSettings] = useState({
    speed: 1.0,
    jobs: 4,
    notopen_action: 'retry',
    tiku_config: {},
    notification_config: {},
    ocr_config: {},
  });

  useEffect(() => {
    fetchConfig();
    fetchCourses();
  }, []);

  const fetchConfig = async () => {
    try {
      const response = await api.get('/config');
      if (response.data.status && response.data.data) {
        const cfg = response.data.data;
        if (cfg.settings) {
          setSettings((prev) => ({
            ...prev,
            ...cfg.settings,
          }));
        }
        if (Array.isArray(cfg.selectedCourses)) {
          setSelectedCourses(cfg.selectedCourses);
        }
      }
    } catch (err) {
      console.error('加载已保存配置失败:', err);
    }
  };

  const fetchCourses = async () => {
    try {
      const response = await api.post('/courses', {
        username: userInfo.username,
        password: userInfo.password,
      });

      if (response.data.status) {
        setCourses(response.data.data);
      }
    } catch (err) {
      console.error('获取课程列表失败:', err);
    } finally {
      setLoading(false);
    }
  };

  const toggleCourse = (courseId) => {
    setSelectedCourses((prev) =>
      prev.includes(courseId)
        ? prev.filter((id) => id !== courseId)
        : [...prev, courseId]
    );
  };

  const handleStartStudy = () => {
    onStartStudy({
      ...settings,
      course_list: selectedCourses.length > 0 ? selectedCourses : courses.map(c => c.courseId),
    });
  };

  const handleSaveConfig = async () => {
    try {
      setSaving(true);
      setSaveStatus('');
      const payload = {
        settings,
        selectedCourses,
      };
      const response = await api.post('/config', payload);
      if (!response.data.status) {
        console.error('保存配置失败:', response.data.msg);
        setSaveStatus(response.data.msg || '保存失败');
      } else {
        setSaveStatus('保存成功');
      }
    } catch (err) {
      console.error('保存配置请求失败:', err);
      setSaveStatus('保存请求失败');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100">
        <div className="text-center">
          <Loader2 className="w-12 h-12 animate-spin text-primary mx-auto mb-4" />
          <p className="text-muted-foreground">加载课程列表中...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 p-6">
      <div className="max-w-6xl mx-auto">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">课程管理</h1>
            <p className="text-muted-foreground mt-1">选择要学习的课程并配置学习参数</p>
          </div>
          <Button variant="outline" onClick={onLogout}>
            <LogOut className="mr-2 h-4 w-4" />
            退出登录
          </Button>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <BookOpen className="mr-2 h-5 w-5" />
                  课程列表
                </CardTitle>
                <CardDescription>
                  选择要自动学习的课程（不选择将学习所有课程）
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-3 max-h-[500px] overflow-y-auto">
                  {courses.map((course) => (
                    <div
                      key={course.courseId}
                      className={`p-4 rounded-lg border-2 cursor-pointer transition-all ${
                        selectedCourses.includes(course.courseId)
                          ? 'border-primary bg-primary/5'
                          : 'border-gray-200 hover:border-gray-300'
                      }`}
                      onClick={() => toggleCourse(course.courseId)}
                    >
                      <div className="flex items-start justify-between">
                        <div className="flex-1">
                          <h3 className="font-semibold text-gray-900">{course.title}</h3>
                          <p className="text-sm text-muted-foreground mt-1">
                            课程ID: {course.courseId}
                          </p>
                        </div>
                        <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${
                          selectedCourses.includes(course.courseId)
                            ? 'border-primary bg-primary'
                            : 'border-gray-300'
                        }`}>
                          {selectedCourses.includes(course.courseId) && (
                            <div className="w-2 h-2 bg-white rounded-full" />
                          )}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>

          <div className="lg:col-span-1">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <Settings className="mr-2 h-5 w-5" />
                  学习配置
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="speed">播放倍速</Label>
                  <Input
                    id="speed"
                    type="number"
                    min="1"
                    max="2"
                    step="0.1"
                    value={settings.speed}
                    onChange={(e) => setSettings({ ...settings, speed: parseFloat(e.target.value) })}
                  />
                  <p className="text-xs text-muted-foreground">范围: 1.0 - 2.0</p>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="jobs">并发章节数</Label>
                  <Input
                    id="jobs"
                    type="number"
                    min="1"
                    max="10"
                    value={settings.jobs}
                    onChange={(e) => setSettings({ ...settings, jobs: parseInt(e.target.value) })}
                  />
                  <p className="text-xs text-muted-foreground">同时处理的章节数量</p>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="notopen">未开放章节处理</Label>
                  <select
                    id="notopen"
                    className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                    value={settings.notopen_action}
                    onChange={(e) => setSettings({ ...settings, notopen_action: e.target.value })}
                  >
                    <option value="retry">重试</option>
                    <option value="ask">询问</option>
                    <option value="continue">跳过</option>
                  </select>
                </div>

                <div className="pt-4 border-t">
                  <AdvancedSettings settings={settings} onChange={setSettings} />
                </div>
              </CardContent>
              <CardFooter className="flex flex-col space-y-2">
                <Button className="w-full" onClick={handleStartStudy}>
                  <Play className="mr-2 h-4 w-4" />
                  开始学习
                </Button>
                <Button
                  type="button"
                  variant="outline"
                  className="w-full text-xs"
                  onClick={handleSaveConfig}
                  disabled={saving}
                >
                  {saving ? '保存中...' : '保存当前配置'}
                </Button>
                {saveStatus && (
                  <p className="text-xs text-muted-foreground text-center">
                    {saveStatus}
                  </p>
                )}
              </CardFooter>
            </Card>

            <Card className="mt-4">
              <CardContent className="pt-6">
                <div className="space-y-2 text-sm">
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">总课程数:</span>
                    <span className="font-semibold">{courses.length}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">已选择:</span>
                    <span className="font-semibold">
                      {selectedCourses.length > 0 ? selectedCourses.length : '全部'}
                    </span>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </div>
    </div>
  );
};

export default CourseSelection;
