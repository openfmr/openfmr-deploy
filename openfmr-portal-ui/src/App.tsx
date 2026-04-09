import { useState, useEffect } from 'react';
import './index.css';
import {
  Stethoscope,
  ShieldCheck,
  BarChart3,
  Settings,
  Activity,
  Server,
  Database,
  KeyRound,
  ExternalLink,
  Loader2,
  CheckCircle2,
  XCircle,
  Clock,
} from 'lucide-react';

/* ------------------------------------------------------------------ */
/*  Types                                                             */
/* ------------------------------------------------------------------ */

interface AppCard {
  id: string;
  title: string;
  description: string;
  url: string;
  icon: React.ReactNode;
  gradient: string;
  glowColor: string;
  category: 'application' | 'infrastructure';
  roles?: string[]; // future: filter by Keycloak roles
  statusEndpoint?: string;
}

/* ------------------------------------------------------------------ */
/*  Application definitions                                           */
/* ------------------------------------------------------------------ */

const applications: AppCard[] = [
  {
    id: 'clinical-ui',
    title: 'Clinical UI',
    description:
      'Patient-facing clinical dashboard for practitioners. Manage encounters, view patient records, and access clinical decision support.',
    url: 'http://localhost:3000',
    icon: <Stethoscope className="w-8 h-8" />,
    gradient: 'from-emerald-500 to-teal-600',
    glowColor: 'shadow-emerald-500/25',
    category: 'application',
    roles: ['clinical_user', 'practitioner'],
  },
  {
    id: 'admin-ui',
    title: 'Admin UI',
    description:
      'Data steward administration console. Manage registries, configure system settings, and oversee data quality workflows.',
    url: 'http://localhost:8000',
    icon: <ShieldCheck className="w-8 h-8" />,
    gradient: 'from-violet-500 to-purple-600',
    glowColor: 'shadow-violet-500/25',
    category: 'application',
    roles: ['admin_user', 'data_steward'],
  },
  {
    id: 'operations-ui',
    title: 'Operations UI',
    description:
      'Operations and billing management interface. Track service delivery, generate reports, and manage financial workflows.',
    url: 'http://localhost:3001',
    icon: <BarChart3 className="w-8 h-8" />,
    gradient: 'from-amber-500 to-orange-600',
    glowColor: 'shadow-amber-500/25',
    category: 'application',
    roles: ['operations_user', 'billing_officer'],
  },
  {
    id: 'openhim-console',
    title: 'OpenHIM Console',
    description:
      'Interoperability layer management. Monitor API transactions, configure channels, and manage mediator orchestration.',
    url: 'http://localhost:9000',
    icon: <Activity className="w-8 h-8" />,
    gradient: 'from-cyan-500 to-blue-600',
    glowColor: 'shadow-cyan-500/25',
    category: 'infrastructure',
    roles: ['admin_user', 'system_admin'],
  },
  {
    id: 'keycloak',
    title: 'Keycloak',
    description:
      'Identity and access management. Create users, assign roles, manage OAuth clients, and configure SSO policies.',
    url: 'http://localhost:8180',
    icon: <KeyRound className="w-8 h-8" />,
    gradient: 'from-rose-500 to-pink-600',
    glowColor: 'shadow-rose-500/25',
    category: 'infrastructure',
    roles: ['system_admin'],
  },
  {
    id: 'hapi-fhir',
    title: 'HAPI FHIR Server',
    description:
      'FHIR-compliant clinical data repository. Browse resources, execute queries, and inspect the underlying health data store.',
    url: 'http://localhost:8080',
    icon: <Database className="w-8 h-8" />,
    gradient: 'from-teal-500 to-emerald-600',
    glowColor: 'shadow-teal-500/25',
    category: 'infrastructure',
    roles: ['admin_user', 'system_admin'],
  },
];

/* ------------------------------------------------------------------ */
/*  Service Health Check (best-effort, client-side)                   */
/* ------------------------------------------------------------------ */

type ServiceStatus = 'checking' | 'online' | 'offline';

function useServiceStatus(url: string): ServiceStatus {
  const [status, setStatus] = useState<ServiceStatus>('checking');

  useEffect(() => {
    let cancelled = false;
    const check = async () => {
      try {
        // We cannot truly fetch cross-origin without CORS, so we use an
        // opaque fetch as a heuristic—if it doesn't throw, the server is up.
        await fetch(url, { mode: 'no-cors', cache: 'no-store' });
        if (!cancelled) setStatus('online');
      } catch {
        if (!cancelled) setStatus('offline');
      }
    };

    // Initial check
    check();
    // Poll every 30 s
    const interval = setInterval(check, 30000);
    return () => {
      cancelled = true;
      clearInterval(interval);
    };
  }, [url]);

  return status;
}

/* ------------------------------------------------------------------ */
/*  Status Badge                                                      */
/* ------------------------------------------------------------------ */

function StatusBadge({ status }: { status: ServiceStatus }) {
  if (status === 'checking') {
    return (
      <span className="inline-flex items-center gap-1.5 text-xs font-medium text-slate-400">
        <Loader2 className="w-3 h-3 animate-spin" />
        Checking…
      </span>
    );
  }
  if (status === 'online') {
    return (
      <span className="inline-flex items-center gap-1.5 text-xs font-medium text-emerald-400">
        <CheckCircle2 className="w-3 h-3" />
        Online
      </span>
    );
  }
  return (
    <span className="inline-flex items-center gap-1.5 text-xs font-medium text-rose-400">
      <XCircle className="w-3 h-3" />
      Offline
    </span>
  );
}

/* ------------------------------------------------------------------ */
/*  Application Card                                                  */
/* ------------------------------------------------------------------ */

function ApplicationCard({ app }: { app: AppCard }) {
  const status = useServiceStatus(app.url);

  return (
    <a
      href={app.url}
      target="_blank"
      rel="noopener noreferrer"
      id={`card-${app.id}`}
      className={`
        group relative flex flex-col rounded-2xl border border-white/[0.08]
        bg-white/[0.04] backdrop-blur-xl p-6
        transition-all duration-300 ease-out
        hover:border-white/[0.15] hover:bg-white/[0.07]
        hover:shadow-2xl hover:${app.glowColor}
        hover:-translate-y-1
      `}
    >
      {/* Gradient icon */}
      <div
        className={`
          flex items-center justify-center w-14 h-14 rounded-xl
          bg-gradient-to-br ${app.gradient}
          shadow-lg mb-5
          transition-transform duration-300 group-hover:scale-110
        `}
      >
        <span className="text-white">{app.icon}</span>
      </div>

      {/* Header row */}
      <div className="flex items-center justify-between mb-2">
        <h3 className="text-lg font-semibold text-white">{app.title}</h3>
        <StatusBadge status={status} />
      </div>

      {/* Description */}
      <p className="text-sm leading-relaxed text-slate-400 flex-1 mb-5">
        {app.description}
      </p>

      {/* Footer */}
      <div className="flex items-center justify-between pt-4 border-t border-white/[0.06]">
        <span className="text-xs text-slate-500 font-mono truncate max-w-[60%]">
          {app.url}
        </span>
        <span
          className={`
            inline-flex items-center gap-1.5 text-sm font-medium
            bg-gradient-to-r ${app.gradient} bg-clip-text text-transparent
            transition-all duration-300
            group-hover:gap-2.5
          `}
        >
          Launch
          <ExternalLink className="w-3.5 h-3.5 text-slate-400 transition-colors group-hover:text-white" />
        </span>
      </div>
    </a>
  );
}

/* ------------------------------------------------------------------ */
/*  Main App                                                          */
/* ------------------------------------------------------------------ */

function App() {
  const [currentTime, setCurrentTime] = useState(new Date());

  useEffect(() => {
    const timer = setInterval(() => setCurrentTime(new Date()), 1000);
    return () => clearInterval(timer);
  }, []);

  const appCategory = applications.filter((a) => a.category === 'application');
  const infraCategory = applications.filter(
    (a) => a.category === 'infrastructure'
  );

  return (
    <div className="min-h-screen flex flex-col">
      {/* ── Subtle animated background blobs ── */}
      <div className="fixed inset-0 -z-10 overflow-hidden pointer-events-none">
        <div className="absolute -top-40 -left-40 w-[600px] h-[600px] rounded-full bg-primary-600/10 blur-[120px] animate-pulse" />
        <div className="absolute top-1/3 -right-32 w-[500px] h-[500px] rounded-full bg-violet-600/10 blur-[120px] animate-pulse [animation-delay:2s]" />
        <div className="absolute -bottom-32 left-1/3 w-[550px] h-[550px] rounded-full bg-emerald-600/8 blur-[120px] animate-pulse [animation-delay:4s]" />
      </div>

      {/* ── Top bar ── */}
      <header className="border-b border-white/[0.06] bg-white/[0.02] backdrop-blur-md">
        <div className="max-w-7xl mx-auto px-6 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="flex items-center justify-center w-10 h-10 rounded-xl bg-gradient-to-br from-primary-500 to-primary-700 shadow-lg shadow-primary-500/25">
              <Server className="w-5 h-5 text-white" />
            </div>
            <div>
              <h1 className="text-lg font-bold text-white tracking-tight">
                OpenFMR
              </h1>
              <p className="text-xs text-slate-500">
                Health Information Exchange
              </p>
            </div>
          </div>

          <div className="flex items-center gap-4">
            <div className="hidden sm:flex items-center gap-2 text-xs text-slate-500">
              <Clock className="w-3.5 h-3.5" />
              {currentTime.toLocaleTimeString([], {
                hour: '2-digit',
                minute: '2-digit',
              })}
            </div>
            <a
              href="http://localhost:8180"
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center gap-2 px-4 py-2 rounded-lg border border-white/[0.08] bg-white/[0.04] text-sm text-slate-300 hover:bg-white/[0.08] hover:text-white transition-all duration-200"
            >
              <Settings className="w-4 h-4" />
              <span className="hidden sm:inline">Manage Users</span>
            </a>
          </div>
        </div>
      </header>

      {/* ── Main content ── */}
      <main className="flex-1 max-w-7xl mx-auto w-full px-6 py-12">
        {/* Hero */}
        <div className="text-center mb-14">
          <h2 className="text-4xl sm:text-5xl font-bold text-white tracking-tight mb-4">
            Welcome to{' '}
            <span className="bg-gradient-to-r from-primary-400 to-primary-600 bg-clip-text text-transparent">
              OpenFMR
            </span>
          </h2>
          <p className="text-lg text-slate-400 max-w-2xl mx-auto">
            Your centralized gateway to the Health Information Exchange.
            <br className="hidden sm:block" />
            Choose an application below to get started.
          </p>
        </div>

        {/* Applications */}
        <section className="mb-16">
          <div className="flex items-center gap-3 mb-6">
            <div className="h-px flex-1 bg-gradient-to-r from-transparent via-white/[0.08] to-transparent" />
            <h3 className="text-sm font-semibold text-slate-400 uppercase tracking-widest whitespace-nowrap">
              Applications
            </h3>
            <div className="h-px flex-1 bg-gradient-to-r from-transparent via-white/[0.08] to-transparent" />
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {appCategory.map((app) => (
              <ApplicationCard key={app.id} app={app} />
            ))}
          </div>
        </section>

        {/* Infrastructure */}
        <section className="mb-16">
          <div className="flex items-center gap-3 mb-6">
            <div className="h-px flex-1 bg-gradient-to-r from-transparent via-white/[0.08] to-transparent" />
            <h3 className="text-sm font-semibold text-slate-400 uppercase tracking-widest whitespace-nowrap">
              Infrastructure
            </h3>
            <div className="h-px flex-1 bg-gradient-to-r from-transparent via-white/[0.08] to-transparent" />
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {infraCategory.map((app) => (
              <ApplicationCard key={app.id} app={app} />
            ))}
          </div>
        </section>
      </main>

      {/* ── Footer ── */}
      <footer className="border-t border-white/[0.06] bg-white/[0.02] backdrop-blur-md">
        <div className="max-w-7xl mx-auto px-6 py-6 flex flex-col sm:flex-row items-center justify-between gap-3">
          <p className="text-xs text-slate-500">
            &copy; {new Date().getFullYear()} OpenFMR &mdash; Health Information
            Exchange Platform
          </p>
          <p className="text-xs text-slate-600">
            Portal v1.0.0
          </p>
        </div>
      </footer>
    </div>
  );
}

export default App;
