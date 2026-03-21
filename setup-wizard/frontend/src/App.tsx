import { useState } from 'react';

function App() {
  const [formData, setFormData] = useState({
    facility_name: '',
    facility_id: '',
    host_ip: '',
    admin_username: 'admin',
    admin_password: '',
    timezone: 'UTC',
  });
  
  const [status, setStatus] = useState<'idle' | 'submitting' | 'success' | 'error'>('idle');
  const [errorMessage, setErrorMessage] = useState('');

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    setFormData((prev) => ({ ...prev, [e.target.name]: e.target.value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setStatus('submitting');
    
    try {
      // The FastAPI backend is running on port 8080 of the host machine
      const hostIp = formData.host_ip || window.location.hostname;
      const apiUrl = `http://${hostIp}:8080/api/setup`;
      
      const response = await fetch(apiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      });
      
      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.detail || 'Setup failed to process');
      }
      
      setStatus('success');
    } catch (err) {
      console.error(err);
      setStatus('error');
      setErrorMessage(err instanceof Error ? err.message : 'Unknown network error');
    }
  };

  if (status === 'success') {
    return (
      <div className="min-h-screen bg-gradient-to-br from-green-50 to-green-100 flex items-center justify-center p-6">
        <div className="max-w-xl w-full bg-white rounded-2xl shadow-xl ring-1 ring-green-100 p-10 text-center">
          <div className="mx-auto flex items-center justify-center h-20 w-20 rounded-full bg-green-100 mb-6">
            <svg className="h-10 w-10 text-green-600" fill="none" viewBox="0 0 24 24" strokeWidth={2} stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <h1 className="text-3xl font-bold text-gray-900 mb-4">Setup Complete!</h1>
          <p className="text-lg text-gray-600 mb-8">
            Your secure <code className="bg-gray-100 text-gray-800 px-2 py-1 rounded">.env.global</code> profile has been dynamically generated and saved to the host machine. All database passwords and security keys have been auto-generated with extreme entropy.
          </p>
          <div className="bg-blue-50 border-l-4 border-blue-500 p-6 text-left rounded-r-lg mb-8">
            <h3 className="font-semibold text-blue-900 mb-2">Next Steps</h3>
            <ol className="list-decimal list-inside text-blue-800 space-y-2">
              <li>Return to your terminal session.</li>
              <li>Press <code className="bg-white/60 px-1.5 py-0.5 rounded font-mono text-sm">Ctrl+C</code> to stop this setup wizard.</li>
              <li>Run <code className="bg-white/60 px-1.5 py-0.5 rounded font-mono text-sm font-bold">bash setup.sh</code> again to boot the OpenFMR system using your new configuration.</li>
            </ol>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 py-12 px-4 sm:px-6 lg:px-8 flex items-center justify-center">
      <div className="max-w-2xl w-full bg-white rounded-2xl shadow-xl ring-1 ring-gray-200 overflow-hidden">
        <div className="bg-primary-600 px-8 py-10 text-center">
          <h2 className="text-3xl font-extrabold text-white tracking-tight">OpenFMR</h2>
          <p className="mt-2 text-primary-100 text-lg">First-Time System Initialization</p>
        </div>
        
        <div className="p-8 sm:p-10">
          <form onSubmit={handleSubmit} className="space-y-8">
            
            {/* Facility Information Section */}
            <div>
              <h3 className="text-lg font-semibold text-gray-900 border-b pb-2 mb-4">Facility Information</h3>
              <div className="grid grid-cols-1 gap-y-6 sm:grid-cols-2 sm:gap-x-6">
                <div className="sm:col-span-2">
                  <label htmlFor="facility_name" className="block text-sm font-medium text-gray-700">Hospital/Facility Name <span className="text-red-500">*</span></label>
                  <input type="text" name="facility_name" id="facility_name" required value={formData.facility_name} onChange={handleChange} placeholder="e.g. Genesis Health System" className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500 sm:text-sm py-2 px-3 border" />
                </div>
                <div>
                  <label htmlFor="facility_id" className="block text-sm font-medium text-gray-700">Facility ID (HFR Alias) <span className="text-red-500">*</span></label>
                  <input type="text" name="facility_id" id="facility_id" required value={formData.facility_id} onChange={handleChange} placeholder="e.g. genesis-main" className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500 sm:text-sm py-2 px-3 border" />
                </div>
                <div>
                  <label htmlFor="timezone" className="block text-sm font-medium text-gray-700">Timezone <span className="text-red-500">*</span></label>
                  <select name="timezone" id="timezone" required value={formData.timezone} onChange={handleChange} className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500 sm:text-sm py-2 px-3 border bg-white">
                    <option value="UTC">UTC</option>
                    <option value="America/New_York">America/New_York (EST/EDT)</option>
                    <option value="Europe/London">Europe/London (GMT/BST)</option>
                    <option value="Asia/Kolkata">Asia/Kolkata (IST)</option>
                    <option value="Asia/Kathmandu">Asia/Kathmandu (NPT)</option>
                    <option value="Australia/Sydney">Australia/Sydney (AEST)</option>
                  </select>
                </div>
              </div>
            </div>

            {/* Network Configuration Section */}
            <div>
              <h3 className="text-lg font-semibold text-gray-900 border-b pb-2 mb-4">Network Configuration</h3>
              <div>
                <label htmlFor="host_ip" className="block text-sm font-medium text-gray-700">Host IP / Base Domain <span className="text-red-500">*</span></label>
                <div className="mt-1 text-sm text-gray-500 mb-2">The IP address or domain name where this server is accessible (e.g., your local LAN IP). Do not include http://</div>
                <input type="text" name="host_ip" id="host_ip" required value={formData.host_ip} onChange={handleChange} placeholder="e.g. 192.168.1.100 or localhost" className="block w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500 sm:text-sm py-2 px-3 border" />
              </div>
            </div>

            {/* Admin Credentials Section */}
            <div>
              <h3 className="text-lg font-semibold text-gray-900 border-b pb-2 mb-4">IAM / Keycloak Administrator</h3>
              <p className="text-sm text-gray-500 mb-4">Set the master credentials for the Identity and Access Management portal.</p>
              <div className="grid grid-cols-1 gap-y-6 sm:grid-cols-2 sm:gap-x-6">
                <div>
                  <label htmlFor="admin_username" className="block text-sm font-medium text-gray-700">Admin Username <span className="text-red-500">*</span></label>
                  <input type="text" name="admin_username" id="admin_username" required value={formData.admin_username} onChange={handleChange} className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500 sm:text-sm py-2 px-3 border" />
                </div>
                <div>
                  <label htmlFor="admin_password" className="block text-sm font-medium text-gray-700">Admin Password <span className="text-red-500">*</span></label>
                  <input type="password" name="admin_password" id="admin_password" required value={formData.admin_password} onChange={handleChange} minLength={8} className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500 sm:text-sm py-2 px-3 border" />
                </div>
              </div>
            </div>

            {/* Error Message */}
            {status === 'error' && (
              <div className="rounded-md bg-red-50 p-4 border border-red-200">
                <div className="flex">
                  <div className="shrink-0">
                    <svg className="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
                      <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z" clipRule="evenodd" />
                    </svg>
                  </div>
                  <div className="ml-3">
                    <h3 className="text-sm font-medium text-red-800">Setup Failed</h3>
                    <div className="mt-2 text-sm text-red-700">
                      <p>{errorMessage}</p>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Submit Button */}
            <div className="pt-4 border-t">
              <button
                type="submit"
                disabled={status === 'submitting'}
                className="w-full flex justify-center py-3 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                {status === 'submitting' ? 'Generating Secure Configuration...' : 'Initialize OpenFMR Deployment'}
              </button>
              <p className="mt-3 text-xs text-center text-gray-500">
                This will automatically generate highly secure random passphrases for all underlying databases and services.
              </p>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}

export default App;
