import { Navigate, Outlet, useLocation } from 'react-router-dom'
import { Skeleton } from '@/components/ui/skeleton'
import { useAuth } from '@/lib/auth'

export function ProtectedRoute() {
  const { loading, isAuthenticated, isStaff } = useAuth()
  const location = useLocation()

  if (loading) {
    return (
      <div className="flex min-h-svh flex-col items-center justify-center gap-3 p-6">
        <Skeleton className="h-8 w-40" />
        <Skeleton className="h-4 w-56" />
      </div>
    )
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace state={{ from: location }} />
  }

  if (!isStaff) {
    return <Navigate to="/forbidden" replace />
  }

  return <Outlet />
}
