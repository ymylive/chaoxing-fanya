import React, { useState } from 'react';
import Login from './components/Login';
import CourseSelection from './components/CourseSelection';
import StudyProgress from './components/StudyProgress';
import api from './api/axios';

function App() {
  const [step, setStep] = useState('login');
  const [userInfo, setUserInfo] = useState(null);
  const [taskId, setTaskId] = useState(null);

  const handleLoginSuccess = (info) => {
    setUserInfo(info);
    setStep('courses');
  };

  const handleStartStudy = async (settings) => {
    try {
      const response = await api.post('/start', {
        username: userInfo.username,
        password: userInfo.password,
        ...settings,
      });

      if (response.data.status) {
        setTaskId(response.data.data.task_id);
        setStep('progress');
      }
    } catch (err) {
      console.error('启动学习任务失败:', err);
      alert('启动学习任务失败，请重试');
    }
  };

  const handleLogout = () => {
    setUserInfo(null);
    setTaskId(null);
    setStep('login');
  };

  const handleBackToHome = () => {
    setTaskId(null);
    setStep('courses');
  };

  return (
    <div className="App">
      {step === 'login' && <Login onLoginSuccess={handleLoginSuccess} />}
      {step === 'courses' && (
        <CourseSelection
          userInfo={userInfo}
          onStartStudy={handleStartStudy}
          onLogout={handleLogout}
        />
      )}
      {step === 'progress' && taskId && (
        <StudyProgress taskId={taskId} onBack={handleBackToHome} />
      )}
    </div>
  );
}

export default App;
