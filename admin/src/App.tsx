import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import { Toaster } from 'sonner'
import { AppErrorBoundary } from '@/components/app-error-boundary'
import { AdminShell } from '@/components/layout/admin-shell'
import { ProtectedRoute } from '@/components/protected-route'
import { AuthProvider } from '@/lib/auth'
import { AuditLogsPage } from '@/pages/audit-logs'
import { DashboardPage } from '@/pages/dashboard'
import { EventDetailPage } from '@/pages/event-detail'
import { EventsPage } from '@/pages/events'
import { ForbiddenPage } from '@/pages/forbidden'
import { LoginPage } from '@/pages/login'
import { ReportsPage } from '@/pages/reports'
import { ToolsPage } from '@/pages/tools'
import { UserDetailPage } from '@/pages/user-detail'
import { UsersPage } from '@/pages/users'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 15_000,
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
})

export default function App() {
  return (
    <AppErrorBoundary>
      <QueryClientProvider client={queryClient}>
        <AuthProvider>
          <BrowserRouter>
            <Routes>
              <Route path="/login" element={<LoginPage />} />
              <Route path="/forbidden" element={<ForbiddenPage />} />
              <Route element={<ProtectedRoute />}>
                <Route element={<AdminShell />}>
                  <Route index element={<DashboardPage />} />
                  <Route path="events" element={<EventsPage />} />
                  <Route path="events/:id" element={<EventDetailPage />} />
                  <Route path="reports" element={<ReportsPage />} />
                  <Route path="users" element={<UsersPage />} />
                  <Route path="users/:id" element={<UserDetailPage />} />
                  <Route path="tools" element={<ToolsPage />} />
                  <Route path="audit" element={<AuditLogsPage />} />
                </Route>
              </Route>
              <Route path="*" element={<Navigate to="/" replace />} />
            </Routes>
          </BrowserRouter>
          <Toaster richColors position="top-right" />
        </AuthProvider>
      </QueryClientProvider>
    </AppErrorBoundary>
  )
}
