import React, { useState, useEffect } from 'react';
import { supabase } from './supabase';
import {
  LayoutDashboard,
  Users,
  UserSquare2,
  BookOpen,
  HelpCircle,
  Settings,
  Plus,
  Edit,
  Trash2,
  Lock,
  LogOut,
  RefreshCw,
  Search,
  CheckCircle2,
  AlertCircle
} from 'lucide-react';
import './App.css';

function App() {
  const [session, setSession] = useState(null);
  const [adminEmail, setAdminEmail] = useState('');
  const [adminPassword, setAdminPassword] = useState('');
  const [authError, setAuthError] = useState('');
  const [activeTab, setActiveTab] = useState('overview');

  // Database Data States
  const [personas, setPersonas] = useState([]);
  const [analytics, setAnalytics] = useState([]);
  const [stories, setStories] = useState([]);
  const [questions, setQuestions] = useState([]);
  const [configs, setConfigs] = useState([]);

  // UI States
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState({ text: '', type: '' });
  const [searchTerm, setSearchTerm] = useState('');

  // Form Editing States
  const [editingPersona, setEditingPersona] = useState(null);
  const [editingStory, setEditingStory] = useState(null);
  const [editingQuestion, setEditingQuestion] = useState(null);
  const [editingConfig, setEditingConfig] = useState(null);

  // New item toggles
  const [showPersonaForm, setShowPersonaForm] = useState(false);
  const [showStoryForm, setShowStoryForm] = useState(false);
  const [showQuestionForm, setShowQuestionForm] = useState(false);

  // Check login session
  useEffect(() => {
    const activeUser = localStorage.getItem('rubyboby_admin_email');
    if (activeUser) {
      setSession(activeUser);
    }
  }, []);

  // Fetch data when session is active
  useEffect(() => {
    if (session) {
      fetchAllData();
    }
  }, [session]);

  const handleLogin = (e) => {
    e.preventDefault();
    if (adminEmail === 'rakibsustbd@gmail.com' && adminPassword === 'rubybobyadmin123') {
      localStorage.setItem('rubyboby_admin_email', adminEmail);
      setSession(adminEmail);
      setAuthError('');
    } else {
      setAuthError('Invalid Admin Email or Password.');
    }
  };

  const handleLogout = () => {
    localStorage.removeItem('rubyboby_admin_email');
    setSession(null);
  };

  const fetchAllData = async () => {
    setLoading(true);
    try {
      await Promise.all([
        fetchPersonas(),
        fetchAnalytics(),
        fetchStories(),
        fetchQuestions(),
        fetchConfigs()
      ]);
    } catch (e) {
      showStatusMessage('Error fetching data: ' + e.message, 'error');
    } finally {
      setLoading(false);
    }
  };

  const showStatusMessage = (text, type = 'success') => {
    setMessage({ text, type });
    setTimeout(() => setMessage({ text: '', type: '' }), 5000);
  };

  // --- CRUD API Calls ---

  const fetchPersonas = async () => {
    const { data, error } = await supabase.from('personas').select('*');
    if (!error) setPersonas(data || []);
  };

  const fetchAnalytics = async () => {
    const { data, error } = await supabase.from('analytics_metrics').select('*');
    if (!error) setAnalytics(data || []);
  };

  const fetchStories = async () => {
    const { data, error } = await supabase.from('stories').select('*');
    if (!error) setStories(data || []);
  };

  const fetchQuestions = async () => {
    const { data, error } = await supabase.from('interactive_questions').select('*');
    if (!error) setQuestions(data || []);
  };

  const fetchConfigs = async () => {
    const { data, error } = await supabase.from('app_config').select('*');
    if (!error) setConfigs(data || []);
  };

  // Personas Save / Delete
  const handleSavePersona = async (e) => {
    e.preventDefault();
    const formData = new FormData(e.target);
    const id = editingPersona?.id || formData.get('id');
    const payload = {
      id,
      name: formData.get('name'),
      traits: formData.get('traits'),
      age: formData.get('age'),
      gender: formData.get('gender'),
      colorValue: parseInt(formData.get('colorValue') || '4294967295'),
      language: formData.get('language'),
      role: formData.get('role'),
      faceZoom: parseFloat(formData.get('faceZoom') || '1.8'),
      faceYOffset: parseFloat(formData.get('faceYOffset') || '-0.2')
    };

    const { error } = await supabase.from('personas').upsert(payload);
    if (!error) {
      showStatusMessage(`Persona "${payload.name}" saved successfully!`);
      setShowPersonaForm(false);
      setEditingPersona(null);
      fetchPersonas();
    } else {
      showStatusMessage('Error: ' + error.message, 'error');
    }
  };

  const handleDeletePersona = async (id, name) => {
    if (window.confirm(`Are you sure you want to delete persona "${name}"?`)) {
      const { error } = await supabase.from('personas').delete().eq('id', id);
      if (!error) {
        showStatusMessage(`Persona "${name}" deleted.`);
        fetchPersonas();
      } else {
        showStatusMessage('Error: ' + error.message, 'error');
      }
    }
  };

  // Stories Save / Delete
  const handleSaveStory = async (e) => {
    e.preventDefault();
    const formData = new FormData(e.target);
    const payload = {
      persona_id: formData.get('persona_id'),
      title: formData.get('title'),
      content: formData.get('content')
    };

    let error;
    if (editingStory?.id) {
      const { error: err } = await supabase.from('stories').update(payload).eq('id', editingStory.id);
      error = err;
    } else {
      const { error: err } = await supabase.from('stories').insert(payload);
      error = err;
    }

    if (!error) {
      showStatusMessage('Story saved successfully!');
      setShowStoryForm(false);
      setEditingStory(null);
      fetchStories();
    } else {
      showStatusMessage('Error: ' + error.message, 'error');
    }
  };

  const handleDeleteStory = async (id) => {
    if (window.confirm('Are you sure you want to delete this story?')) {
      const { error } = await supabase.from('stories').delete().eq('id', id);
      if (!error) {
        showStatusMessage('Story deleted.');
        fetchStories();
      } else {
        showStatusMessage('Error: ' + error.message, 'error');
      }
    }
  };

  // Questions Save / Delete
  const handleSaveQuestion = async (e) => {
    e.preventDefault();
    const formData = new FormData(e.target);
    const options = [
      formData.get('optionA'),
      formData.get('optionB'),
      formData.get('optionC')
    ].filter(Boolean);

    const payload = {
      persona_id: formData.get('persona_id'),
      question_text: formData.get('question_text'),
      options,
      correct_answer: formData.get('correct_answer'),
      explanation: formData.get('explanation')
    };

    let error;
    if (editingQuestion?.id) {
      const { error: err } = await supabase.from('interactive_questions').update(payload).eq('id', editingQuestion.id);
      error = err;
    } else {
      const { error: err } = await supabase.from('interactive_questions').insert(payload);
      error = err;
    }

    if (!error) {
      showStatusMessage('Question saved successfully!');
      setShowQuestionForm(false);
      setEditingQuestion(null);
      fetchQuestions();
    } else {
      showStatusMessage('Error: ' + error.message, 'error');
    }
  };

  const handleDeleteQuestion = async (id) => {
    if (window.confirm('Are you sure you want to delete this question?')) {
      const { error } = await supabase.from('interactive_questions').delete().eq('id', id);
      if (!error) {
        showStatusMessage('Question deleted.');
        fetchQuestions();
      } else {
        showStatusMessage('Error: ' + error.message, 'error');
      }
    }
  };

  // Config Update
  const handleSaveConfig = async (e) => {
    e.preventDefault();
    const formData = new FormData(e.target);
    const key = editingConfig?.key || formData.get('key');
    const payload = {
      key,
      value: formData.get('value'),
      description: formData.get('description')
    };

    const { error } = await supabase.from('app_config').upsert(payload);
    if (!error) {
      showStatusMessage('System Config updated!');
      setEditingConfig(null);
      fetchConfigs();
    } else {
      showStatusMessage('Error: ' + error.message, 'error');
    }
  };

  // --- Helper Calculations for Overview Analytics ---
  const allUserStats = analytics.filter(r => r.persona_id === 'All' && r.time_range === 'weekly');
  const uniqueUsers = Array.from(new Set(analytics.map(r => r.user_email)));
  const totalTalkTime = analytics
    .filter(r => r.persona_id === 'All' && r.time_range === 'weekly')
    .reduce((sum, r) => sum + (r.total_minutes || 0), 0);
  const totalChats = analytics
    .filter(r => r.persona_id === 'All' && r.time_range === 'weekly')
    .reduce((sum, r) => sum + (r.chats_count || 0), 0);

  // Persona popularity (Weekly total minutes per persona across all users)
  const personaUsage = {};
  analytics
    .filter(r => r.persona_id !== 'All' && r.time_range === 'weekly')
    .forEach(r => {
      personaUsage[r.persona_id] = (personaUsage[r.persona_id] || 0) + (r.total_minutes || 0);
    });

  const personaChartMax = Math.max(...Object.values(personaUsage), 1);

  // Cognitive Focus weights aggregation
  let totalSci = 0, totalSoc = 0, totalLang = 0, totalLog = 0, totalFocusCount = 0;
  analytics
    .filter(r => r.persona_id === 'All' && r.time_range === 'weekly')
    .forEach(r => {
      const focus = r.cognitive_focus;
      if (focus) {
        totalSci += focus.science || 0;
        totalSoc += focus.social || 0;
        totalLang += focus.language || 0;
        totalLog += focus.logic || 0;
        totalFocusCount++;
      }
    });

  const avgFocus = {
    science: totalFocusCount > 0 ? (totalSci / totalFocusCount) * 100 : 25,
    social: totalFocusCount > 0 ? (totalSoc / totalFocusCount) * 100 : 25,
    language: totalFocusCount > 0 ? (totalLang / totalFocusCount) * 100 : 25,
    logic: totalFocusCount > 0 ? (totalLog / totalFocusCount) * 100 : 25,
  };

  // Filtered Users List
  const userList = analytics
    .filter(r => r.persona_id === 'All' && r.time_range === 'weekly')
    .filter(r => r.user_email.toLowerCase().includes(searchTerm.toLowerCase()));

  // Auth Guard
  if (!session) {
    return (
      <div className="auth-wrapper">
        <div className="auth-card animate-fade-in">
          <div className="auth-header">
            <div className="auth-logo">🤖</div>
            <h1 className="auth-title">Ruby Boby</h1>
            <p className="auth-subtitle">Platform Admin Portal</p>
          </div>
          {authError && (
            <div style={{ background: 'rgba(239, 68, 68, 0.1)', border: '1px solid rgba(239, 68, 68, 0.3)', color: '#fca5a5', padding: '12px', borderRadius: '12px', fontSize: '13px', marginBottom: '20px', display: 'flex', gap: '8px', alignItems: 'center' }}>
              <AlertCircle size={16} /> {authError}
            </div>
          )}
          <form onSubmit={handleLogin} style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
            <div className="form-group">
              <label>Admin Email</label>
              <input
                type="email"
                className="form-input"
                placeholder="name@example.com"
                value={adminEmail}
                onChange={(e) => setAdminEmail(e.target.value)}
                required
              />
            </div>
            <div className="form-group">
              <label>Admin Password</label>
              <input
                type="password"
                className="form-input"
                placeholder="••••••••"
                value={adminPassword}
                onChange={(e) => setAdminPassword(e.target.value)}
                required
              />
            </div>
            <button type="submit" className="btn btn-primary" style={{ justifyContent: 'center', padding: '14px', fontSize: '15px' }}>
              <Lock size={16} /> Authenticate
            </button>
          </form>
        </div>
      </div>
    );
  }

  return (
    <div className="app-container">
      {/* Sidebar Navigation */}
      <aside className="sidebar">
        <div className="logo-section">
          <div className="logo-icon">🤖</div>
          <span className="logo-text">Ruby Boby</span>
        </div>
        <nav className="nav-links">
          <li className={`nav-item ${activeTab === 'overview' ? 'active' : ''}`} onClick={() => setActiveTab('overview')}>
            <LayoutDashboard size={18} /> Overview
          </li>
          <li className={`nav-item ${activeTab === 'users' ? 'active' : ''}`} onClick={() => { setActiveTab('users'); setEditingPersona(null); }}>
            <Users size={18} /> User Analytics
          </li>
          <li className={`nav-item ${activeTab === 'personas' ? 'active' : ''}`} onClick={() => { setActiveTab('personas'); setEditingPersona(null); }}>
            <UserSquare2 size={18} /> Manage Personas
          </li>
          <li className={`nav-item ${activeTab === 'stories' ? 'active' : ''}`} onClick={() => { setActiveTab('stories'); setEditingStory(null); }}>
            <BookOpen size={18} /> Story Archive
          </li>
          <li className={`nav-item ${activeTab === 'mcq' ? 'active' : ''}`} onClick={() => { setActiveTab('mcq'); setEditingQuestion(null); }}>
            <HelpCircle size={18} /> MCQ Bank
          </li>
          <li className={`nav-item ${activeTab === 'config' ? 'active' : ''}`} onClick={() => { setActiveTab('config'); setEditingConfig(null); }}>
            <Settings size={18} /> System Config
          </li>
        </nav>
        <div className="sidebar-footer">
          <button onClick={handleLogout} className="btn btn-secondary" style={{ width: '100%', justifyContent: 'center' }}>
            <LogOut size={16} /> Sign Out
          </button>
        </div>
      </aside>

      {/* Main Content Pane */}
      <main className="main-content">
        <header className="header-section">
          <div>
            <h1 className="page-title">
              {activeTab === 'overview' && 'System Overview'}
              {activeTab === 'users' && 'User Engagement & Metrics'}
              {activeTab === 'personas' && 'Child Friends & Personas'}
              {activeTab === 'stories' && 'Story Archive Manager'}
              {activeTab === 'mcq' && 'Interactive MCQ Bank'}
              {activeTab === 'config' && 'Credential & Key Manager'}
            </h1>
            <p className="page-subtitle">Ruby Boby Administration Dashboard</p>
          </div>
          <div className="btn-group">
            <button className="btn btn-secondary" onClick={fetchAllData} disabled={loading}>
              <RefreshCw size={16} className={loading ? 'spin' : ''} /> Sync
            </button>
          </div>
        </header>

        {/* Global status alert message */}
        {message.text && (
          <div style={{
            background: message.type === 'error' ? 'rgba(239, 68, 68, 0.15)' : 'rgba(16, 185, 129, 0.15)',
            border: `1px solid ${message.type === 'error' ? 'rgba(239, 68, 68, 0.3)' : 'rgba(16, 185, 129, 0.3)'}`,
            color: message.type === 'error' ? '#fca5a5' : '#a7f3d0',
            padding: '16px 24px',
            borderRadius: '16px',
            marginBottom: '32px',
            display: 'flex',
            alignItems: 'center',
            gap: '12px',
            fontSize: '14px',
            fontWeight: '600'
          }} className="animate-fade-in">
            {message.type === 'error' ? <AlertCircle size={18} /> : <CheckCircle2 size={18} />}
            {message.text}
          </div>
        )}

        {/* ================== TAB: OVERVIEW ================== */}
        {activeTab === 'overview' && (
          <div className="animate-fade-in">
            {/* Overview Summary Cards */}
            <div className="metrics-grid">
              <div className="metric-card">
                <div className="metric-icon-container" style={{ background: 'rgba(59, 130, 246, 0.15)', color: varColor('--accent-blue') }}>
                  <Users size={24} />
                </div>
                <div className="metric-details">
                  <h3>Total Registered Kids</h3>
                  <div className="value">{uniqueUsers.length}</div>
                </div>
              </div>
              <div className="metric-card">
                <div className="metric-icon-container" style={{ background: 'rgba(236, 72, 153, 0.15)', color: varColor('--accent-pink') }}>
                  <LayoutDashboard size={24} />
                </div>
                <div className="metric-details">
                  <h3>Total Chat Sessions</h3>
                  <div className="value">{totalChats}</div>
                </div>
              </div>
              <div className="metric-card">
                <div className="metric-icon-container" style={{ background: 'rgba(168, 85, 247, 0.15)', color: varColor('--accent-purple') }}>
                  <BookOpen size={24} />
                </div>
                <div className="metric-details">
                  <h3>Total Talk Time</h3>
                  <div className="value">{totalTalkTime.toFixed(1)}m</div>
                </div>
              </div>
              <div className="metric-card">
                <div className="metric-icon-container" style={{ background: 'rgba(16, 185, 129, 0.15)', color: varColor('--accent-green') }}>
                  <HelpCircle size={24} />
                </div>
                <div className="metric-details">
                  <h3>Active Personas</h3>
                  <div className="value">{personas.length}</div>
                </div>
              </div>
            </div>

            {/* Custom SVG Charts */}
            <div className="chart-row">
              {/* Popular Personas SVG Bar Chart */}
              <div className="chart-card">
                <h2 className="chart-title">Popular Personas (Total Minutes)</h2>
                <div className="chart-placeholder">
                  {Object.keys(personaUsage).length > 0 ? (
                    Object.entries(personaUsage).map(([id, val]) => {
                      const pct = (val / personaChartMax) * 100;
                      return (
                        <div key={id} className="chart-bar-container">
                          <div className="chart-tooltip">{val.toFixed(1)} mins</div>
                          <div className="chart-bar" style={{
                            height: `${pct}%`,
                            background: id === 'Ruby' ? varColor('--accent-pink') : (id === 'Boby' ? varColor('--accent-blue') : varColor('--accent-purple'))
                          }} />
                          <span className="chart-label">{id}</span>
                        </div>
                      );
                    })
                  ) : (
                    <div style={{ margin: 'auto', color: varColor('--text-secondary') }}>No conversation history recorded.</div>
                  )}
                </div>
              </div>

              {/* Cognitive Focus Custom Chart */}
              <div className="chart-card">
                <h2 className="chart-title">Cognitive Development Area Mix</h2>
                <div className="donut-chart-container">
                  <div style={{ position: 'relative', width: '140px', height: '140px' }}>
                    {/* SVG representation of aggregated focus split */}
                    <svg viewBox="0 0 36 36" style={{ width: '100%', height: '100%', transform: 'rotate(-90deg)' }}>
                      <circle cx="18" cy="18" r="15.915" fill="none" stroke="rgba(255,255,255,0.05)" strokeWidth="4.2" />
                      {/* Science (Blue) */}
                      <circle cx="18" cy="18" r="15.915" fill="none" stroke={varColor('--accent-blue')} strokeWidth="4.2"
                        strokeDasharray={`${avgFocus.science} ${100 - avgFocus.science}`} strokeDashoffset="0" />
                      {/* Social (Pink) */}
                      <circle cx="18" cy="18" r="15.915" fill="none" stroke={varColor('--accent-pink')} strokeWidth="4.2"
                        strokeDasharray={`${avgFocus.social} ${100 - avgFocus.social}`} strokeDashoffset={-avgFocus.science} />
                      {/* Language (Green) */}
                      <circle cx="18" cy="18" r="15.915" fill="none" stroke={varColor('--accent-green')} strokeWidth="4.2"
                        strokeDasharray={`${avgFocus.language} ${100 - avgFocus.language}`} strokeDashoffset={-(avgFocus.science + avgFocus.social)} />
                      {/* Logic (Amber) */}
                      <circle cx="18" cy="18" r="15.915" fill="none" stroke={varColor('--accent-amber')} strokeWidth="4.2"
                        strokeDasharray={`${avgFocus.logic} ${100 - avgFocus.logic}`} strokeDashoffset={-(avgFocus.science + avgFocus.social + avgFocus.language)} />
                    </svg>
                    <div style={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -50%)', fontWeight: '800', fontSize: '13px', textAlign: 'center' }}>
                      Focus<br /><span style={{ fontSize: '11px', color: varColor('--text-secondary') }}>Overview</span>
                    </div>
                  </div>
                  <div className="donut-legend">
                    <div className="legend-item"><div className="legend-color" style={{ background: varColor('--accent-blue') }} /> Science ({avgFocus.science.toFixed(0)}%)</div>
                    <div className="legend-item"><div className="legend-color" style={{ background: varColor('--accent-pink') }} /> Social ({avgFocus.social.toFixed(0)}%)</div>
                    <div className="legend-item"><div className="legend-color" style={{ background: varColor('--accent-green') }} /> Language ({avgFocus.language.toFixed(0)}%)</div>
                    <div className="legend-item"><div className="legend-color" style={{ background: varColor('--accent-amber') }} /> Logic ({avgFocus.logic.toFixed(0)}%)</div>
                  </div>
                </div>
              </div>
            </div>

            {/* Quick Summary list of recently active users */}
            <div className="content-panel">
              <div className="panel-header">
                <h2 className="panel-title">Active User Registry</h2>
              </div>
              <div className="table-container">
                <table className="admin-table">
                  <thead>
                    <tr>
                      <th>Child User</th>
                      <th>Chats Completed</th>
                      <th>Total Talk Time</th>
                      <th>Avg. engagement</th>
                      <th>Sentiment / Mood Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {allUserStats.slice(0, 5).map(u => (
                      <tr key={u.id}>
                        <td style={{ fontWeight: '700' }}>{u.user_email}</td>
                        <td><span className="badge badge-blue">{u.chats_count} chats</span></td>
                        <td>{u.total_minutes.toFixed(1)} mins</td>
                        <td>{u.avg_engagement.toFixed(1)}m/session</td>
                        <td style={{ fontSize: '13px', color: varColor('--text-secondary') }}>{u.sentiment || 'Curious & Learning'}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* ================== TAB: USERS ================== */}
        {activeTab === 'users' && (
          <div className="content-panel animate-fade-in">
            <div className="panel-header" style={{ flexWrap: 'wrap', gap: '16px' }}>
              <h2 className="panel-title">User Metrics</h2>
              <div style={{ position: 'relative' }}>
                <input
                  type="text"
                  placeholder="Search user email..."
                  className="form-input"
                  style={{ paddingLeft: '36px', width: '240px' }}
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                />
                <Search size={16} style={{ position: 'absolute', left: '12px', top: '14px', color: varColor('--text-secondary') }} />
              </div>
            </div>
            <div className="table-container">
              <table className="admin-table">
                <thead>
                  <tr>
                    <th>User Email</th>
                    <th>Weekly Minutes</th>
                    <th>Weekly Chats</th>
                    <th>Average Engagement</th>
                    <th>Insights / Sentiment Status</th>
                  </tr>
                </thead>
                <tbody>
                  {userList.map(u => (
                    <tr key={u.id}>
                      <td style={{ fontWeight: '700' }}>{u.user_email}</td>
                      <td>{u.total_minutes.toFixed(1)}m</td>
                      <td><span className="badge badge-pink">{u.chats_count} chats</span></td>
                      <td>{u.avg_engagement.toFixed(1)} mins</td>
                      <td style={{ fontSize: '13px', color: varColor('--text-secondary'), maxWidth: '300px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }} title={u.sentiment}>
                        {u.sentiment}
                      </td>
                    </tr>
                  ))}
                  {userList.length === 0 && (
                    <tr>
                      <td colSpan="5" style={{ textAlign: 'center', padding: '30px', color: varColor('--text-secondary') }}>
                        No user records found matching search.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* ================== TAB: PERSONAS ================== */}
        {activeTab === 'personas' && (
          <div className="animate-fade-in">
            {showPersonaForm || editingPersona ? (
              <div className="content-panel">
                <div className="panel-header">
                  <h2 className="panel-title">{editingPersona ? `Edit Persona: ${editingPersona.name}` : 'Create New Persona'}</h2>
                  <button className="btn btn-secondary" onClick={() => { setShowPersonaForm(false); setEditingPersona(null); }}>Cancel</button>
                </div>
                <form onSubmit={handleSavePersona}>
                  <div className="form-grid">
                    <div className="form-group">
                      <label>Unique ID (Single Word)</label>
                      <input
                        type="text"
                        name="id"
                        className="form-input"
                        placeholder="e.g. Astro"
                        defaultValue={editingPersona?.id || ''}
                        disabled={!!editingPersona}
                        required
                      />
                    </div>
                    <div className="form-group">
                      <label>Character Name</label>
                      <input
                        type="text"
                        name="name"
                        className="form-input"
                        placeholder="e.g. Captain Astro"
                        defaultValue={editingPersona?.name || ''}
                        required
                      />
                    </div>
                    <div className="form-group">
                      <label>Age</label>
                      <input
                        type="text"
                        name="age"
                        className="form-input"
                        placeholder="e.g. 8"
                        defaultValue={editingPersona?.age || '5'}
                        required
                      />
                    </div>
                    <div className="form-group">
                      <label>Gender</label>
                      <select name="gender" className="form-select" defaultValue={editingPersona?.gender || 'Boy'}>
                        <option value="Boy">Boy</option>
                        <option value="Girl">Girl</option>
                        <option value="Robot">Robot</option>
                        <option value="Unspecified">Unspecified</option>
                      </select>
                    </div>
                    <div className="form-group">
                      <label>Role</label>
                      <input
                        type="text"
                        name="role"
                        className="form-input"
                        placeholder="e.g. Friend, Teacher, Mentor"
                        defaultValue={editingPersona?.role || 'Friend'}
                        required
                      />
                    </div>
                    <div className="form-group">
                      <label>Language</label>
                      <input
                        type="text"
                        name="language"
                        className="form-input"
                        placeholder="e.g. English, Bangla, Spanish"
                        defaultValue={editingPersona?.language || 'English'}
                        required
                      />
                    </div>
                    <div className="form-group">
                      <label>Avatar Color (ARGB Decimal)</label>
                      <input
                        type="text"
                        name="colorValue"
                        className="form-input"
                        placeholder="e.g. 4294967295 (Default White)"
                        defaultValue={editingPersona?.colorValue || '4294967295'}
                      />
                    </div>
                    <div className="form-group">
                      <label>Camera Zoom</label>
                      <input
                        type="number"
                        step="0.1"
                        name="faceZoom"
                        className="form-input"
                        defaultValue={editingPersona?.faceZoom || '1.8'}
                      />
                    </div>
                    <div className="form-group">
                      <label>Camera Y Offset</label>
                      <input
                        type="number"
                        step="0.05"
                        name="faceYOffset"
                        className="form-input"
                        defaultValue={editingPersona?.faceYOffset || '-0.2'}
                      />
                    </div>
                    <div className="form-group full-width">
                      <label>Personality Traits / Prompt Instructions</label>
                      <textarea
                        name="traits"
                        className="form-textarea"
                        placeholder="Define prompt behavior traits..."
                        defaultValue={editingPersona?.traits || ''}
                        required
                      />
                    </div>
                  </div>
                  <button type="submit" className="btn btn-primary">Save Persona</button>
                </form>
              </div>
            ) : (
              <div className="content-panel">
                <div className="panel-header">
                  <h2 className="panel-title">Persona Profiles</h2>
                  <button className="btn btn-primary" onClick={() => setShowPersonaForm(true)}>
                    <Plus size={16} /> Create Persona
                  </button>
                </div>
                <div className="table-container">
                  <table className="admin-table">
                    <thead>
                      <tr>
                        <th>Avatar</th>
                        <th>Name (ID)</th>
                        <th>Role / Gender</th>
                        <th>Language</th>
                        <th>Traits Description</th>
                        <th>Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {personas.map(p => (
                        <tr key={p.id}>
                          <td>
                            <div style={{
                              width: '40px',
                              height: '40px',
                              borderRadius: '12px',
                              background: `#${(p.colorValue & 0xFFFFFF).toString(16).padStart(6, '0')}`,
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                              color: 'white',
                              fontWeight: 'bold',
                              fontSize: '18px'
                            }}>
                              {p.name[0]}
                            </div>
                          </td>
                          <td style={{ fontWeight: '700' }}>
                            {p.name} <span style={{ color: varColor('--text-secondary'), fontWeight: '400', fontSize: '12px' }}>({p.id})</span>
                          </td>
                          <td>
                            <span className="badge badge-purple">{p.role}</span>
                            <span style={{ marginLeft: '6px', fontSize: '13px', color: varColor('--text-secondary') }}>Age {p.age} {p.gender}</span>
                          </td>
                          <td>{p.language}</td>
                          <td style={{ fontSize: '13px', color: varColor('--text-secondary'), maxWidth: '240px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                            {p.traits}
                          </td>
                          <td>
                            <div className="btn-group">
                              <button className="btn btn-secondary btn-icon" onClick={() => setEditingPersona(p)} title="Edit Persona">
                                <Edit size={14} />
                              </button>
                              <button className="btn btn-danger btn-icon" onClick={() => handleDeletePersona(p.id, p.name)} title="Delete Persona">
                                <Trash2 size={14} />
                              </button>
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}
          </div>
        )}

        {/* ================== TAB: STORIES ================== */}
        {activeTab === 'stories' && (
          <div className="animate-fade-in">
            {showStoryForm || editingStory ? (
              <div className="content-panel">
                <div className="panel-header">
                  <h2 className="panel-title">{editingStory ? 'Edit Story Details' : 'Add Story to Archive'}</h2>
                  <button className="btn btn-secondary" onClick={() => { setShowStoryForm(false); setEditingStory(null); }}>Cancel</button>
                </div>
                <form onSubmit={handleSaveStory}>
                  <div className="form-grid">
                    <div className="form-group">
                      <label>Character Persona</label>
                      <select name="persona_id" className="form-select" defaultValue={editingStory?.persona_id || 'Ruby'}>
                        <option value="All">All Friends</option>
                        {personas.map(p => (
                          <option key={p.id} value={p.id}>{p.name}</option>
                        ))}
                      </select>
                    </div>
                    <div className="form-group" style={{ gridColumn: 'span 2' }}>
                      <label>Story Title</label>
                      <input
                        type="text"
                        name="title"
                        className="form-input"
                        placeholder="e.g. The Rocket and the Star"
                        defaultValue={editingStory?.title || ''}
                        required
                      />
                    </div>
                    <div className="form-group full-width">
                      <label>Story Content</label>
                      <textarea
                        name="content"
                        className="form-textarea"
                        placeholder="Write or paste the story script here..."
                        defaultValue={editingStory?.content || ''}
                        required
                      />
                    </div>
                  </div>
                  <button type="submit" className="btn btn-primary">Save Story to Archive</button>
                </form>
              </div>
            ) : (
              <div className="content-panel">
                <div className="panel-header">
                  <h2 className="panel-title">Story Archive</h2>
                  <button className="btn btn-primary" onClick={() => setShowStoryForm(true)}>
                    <Plus size={16} /> Add Story
                  </button>
                </div>
                <div className="table-container">
                  <table className="admin-table">
                    <thead>
                      <tr>
                        <th>Title</th>
                        <th>Teller (Persona)</th>
                        <th>Story Outline</th>
                        <th>Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {stories.map(s => (
                        <tr key={s.id}>
                          <td style={{ fontWeight: '700' }}>{s.title}</td>
                          <td><span className="badge badge-pink">{s.persona_id}</span></td>
                          <td style={{ fontSize: '13px', color: varColor('--text-secondary'), maxWidth: '400px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                            {s.content}
                          </td>
                          <td>
                            <div className="btn-group">
                              <button className="btn btn-secondary btn-icon" onClick={() => setEditingStory(s)} title="Edit Story">
                                <Edit size={14} />
                              </button>
                              <button className="btn btn-danger btn-icon" onClick={() => handleDeleteStory(s.id)} title="Delete Story">
                                <Trash2 size={14} />
                              </button>
                            </div>
                          </td>
                        </tr>
                      ))}
                      {stories.length === 0 && (
                        <tr>
                          <td colSpan="4" style={{ textAlign: 'center', padding: '30px', color: varColor('--text-secondary') }}>
                            Story archive is currently empty. Add a story to get started!
                          </td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>
              </div>
            )}
          </div>
        )}

        {/* ================== TAB: MCQ BANK ================== */}
        {activeTab === 'mcq' && (
          <div className="animate-fade-in">
            {showQuestionForm || editingQuestion ? (
              <div className="content-panel">
                <div className="panel-header">
                  <h2 className="panel-title">{editingQuestion ? 'Edit Question Details' : 'Add MCQ to Bank'}</h2>
                  <button className="btn btn-secondary" onClick={() => { setShowQuestionForm(false); setEditingQuestion(null); }}>Cancel</button>
                </div>
                <form onSubmit={handleSaveQuestion}>
                  <div className="form-grid">
                    <div className="form-group">
                      <label>Character Persona</label>
                      <select name="persona_id" className="form-select" defaultValue={editingQuestion?.persona_id || 'Boby'}>
                        {personas.map(p => (
                          <option key={p.id} value={p.id}>{p.name}</option>
                        ))}
                      </select>
                    </div>
                    <div className="form-group" style={{ gridColumn: 'span 2' }}>
                      <label>Question Prompt / Text</label>
                      <input
                        type="text"
                        name="question_text"
                        className="form-input"
                        placeholder="e.g. Which planet is closest to the Sun?"
                        defaultValue={editingQuestion?.question_text || ''}
                        required
                      />
                    </div>
                    <div className="form-group">
                      <label>Option A</label>
                      <input
                        type="text"
                        name="optionA"
                        className="form-input"
                        placeholder="Option A"
                        defaultValue={editingQuestion?.options?.[0] || ''}
                        required
                      />
                    </div>
                    <div className="form-group">
                      <label>Option B</label>
                      <input
                        type="text"
                        name="optionB"
                        className="form-input"
                        placeholder="Option B"
                        defaultValue={editingQuestion?.options?.[1] || ''}
                        required
                      />
                    </div>
                    <div className="form-group">
                      <label>Option C</label>
                      <input
                        type="text"
                        name="optionC"
                        className="form-input"
                        placeholder="Option C (Optional)"
                        defaultValue={editingQuestion?.options?.[2] || ''}
                      />
                    </div>
                    <div className="form-group">
                      <label>Correct Answer (Exact text of the correct option)</label>
                      <input
                        type="text"
                        name="correct_answer"
                        className="form-input"
                        placeholder="e.g. Mercury"
                        defaultValue={editingQuestion?.correct_answer || ''}
                        required
                      />
                    </div>
                    <div className="form-group full-width">
                      <label>Explanation / Fun Fact</label>
                      <textarea
                        name="explanation"
                        className="form-textarea"
                        placeholder="Fun fact explanation when the child answers..."
                        defaultValue={editingQuestion?.explanation || ''}
                      />
                    </div>
                  </div>
                  <button type="submit" className="btn btn-primary">Save MCQ Prompt</button>
                </form>
              </div>
            ) : (
              <div className="content-panel">
                <div className="panel-header">
                  <h2 className="panel-title">Interactive Multiple-Choice Question Bank</h2>
                  <button className="btn btn-primary" onClick={() => setShowQuestionForm(true)}>
                    <Plus size={16} /> Add Question Prompt
                  </button>
                </div>
                <div className="table-container">
                  <table className="admin-table">
                    <thead>
                      <tr>
                        <th>Question</th>
                        <th>Target Persona</th>
                        <th>Options List</th>
                        <th>Correct Answer</th>
                        <th>Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {questions.map(q => (
                        <tr key={q.id}>
                          <td style={{ fontWeight: '700' }}>{q.question_text}</td>
                          <td><span className="badge badge-purple">{q.persona_id}</span></td>
                          <td>
                            <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' }}>
                              {q.options?.map((o, idx) => (
                                <span key={idx} className="badge badge-blue">{o}</span>
                              ))}
                            </div>
                          </td>
                          <td><span className="badge badge-green">{q.correct_answer}</span></td>
                          <td>
                            <div className="btn-group">
                              <button className="btn btn-secondary btn-icon" onClick={() => setEditingQuestion(q)} title="Edit MCQ">
                                <Edit size={14} />
                              </button>
                              <button className="btn btn-danger btn-icon" onClick={() => handleDeleteQuestion(q.id)} title="Delete MCQ">
                                <Trash2 size={14} />
                              </button>
                            </div>
                          </td>
                        </tr>
                      ))}
                      {questions.length === 0 && (
                        <tr>
                          <td colSpan="5" style={{ textAlign: 'center', padding: '30px', color: varColor('--text-secondary') }}>
                            MCQ Bank is empty. Add educational interactive prompts here!
                          </td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>
              </div>
            )}
          </div>
        )}

        {/* ================== TAB: CONFIG ================== */}
        {activeTab === 'config' && (
          <div className="content-panel animate-fade-in">
            <div className="panel-header">
              <h2 className="panel-title">System Credentials & External Keys Manager</h2>
            </div>
            
            {/* Show config forms if editing */}
            {editingConfig && (
              <form onSubmit={handleSaveConfig} style={{ marginBottom: '40px', paddingBottom: '30px', borderBottom: '1px solid var(--glass-border)' }}>
                <h3 style={{ fontSize: '15px', fontWeight: '800', marginBottom: '16px' }}>Edit System Value: {editingConfig.key}</h3>
                <div className="form-grid">
                  <div className="form-group" style={{ gridColumn: 'span 2' }}>
                    <label>Configuration Value</label>
                    <input
                      type="text"
                      name="value"
                      className="form-input"
                      defaultValue={editingConfig.value}
                      required
                    />
                  </div>
                  <div className="form-group" style={{ gridColumn: 'span 2' }}>
                    <label>Description / Internal Note</label>
                    <input
                      type="text"
                      name="description"
                      className="form-input"
                      defaultValue={editingConfig.description}
                    />
                  </div>
                </div>
                <div className="btn-group">
                  <button type="submit" className="btn btn-primary">Save Config Changes</button>
                  <button type="button" className="btn btn-secondary" onClick={() => setEditingConfig(null)}>Cancel</button>
                </div>
              </form>
            )}

            <div className="table-container">
              <table className="admin-table">
                <thead>
                  <tr>
                    <th>Key Name</th>
                    <th>Integration Value</th>
                    <th>Description</th>
                    <th>Last Synchronized</th>
                    <th>Action</th>
                  </tr>
                </thead>
                <tbody>
                  {configs.map(c => (
                    <tr key={c.key}>
                      <td style={{ fontWeight: '700' }}><span className="badge badge-amber">{c.key}</span></td>
                      <td style={{ fontFamily: 'monospace', fontSize: '13px' }}>
                        {c.key.includes('key') || c.key.includes('secret') ? '••••••••' + c.value.slice(-6) : c.value}
                      </td>
                      <td>{c.description || 'Global configuration parameter.'}</td>
                      <td style={{ fontSize: '13px', color: varColor('--text-secondary') }}>
                        {new Date(c.updated_at || Date.now()).toLocaleString()}
                      </td>
                      <td>
                        <button className="btn btn-secondary" onClick={() => setEditingConfig(c)}>
                          <Edit size={14} /> Edit Key
                        </button>
                      </td>
                    </tr>
                  ))}
                  {configs.length === 0 && (
                    <tr>
                      <td colSpan="5" style={{ textAlign: 'center', padding: '30px', color: varColor('--text-secondary') }}>
                        No global config keys defined in `app_config` table yet.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}

// Utility to resolve color variables locally in CSS bindings
function varColor(variableName) {
  return `var(${variableName})`;
}

export default App;
