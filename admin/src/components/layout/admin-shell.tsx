import {
  FlagIcon,
  LayoutDashboardIcon,
  LogOutIcon,
  MapIcon,
  MenuIcon,
  ScrollTextIcon,
  WrenchIcon,
  UsersIcon,
} from 'lucide-react'
import { useState } from 'react'
import { NavLink, Outlet } from 'react-router-dom'
import { SessionExpiryWatcher } from '@/components/session-expiry-watcher'
import { Button } from '@/components/ui/button'
import { Separator } from '@/components/ui/separator'
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetHeader,
  SheetTitle,
} from '@/components/ui/sheet'
import { useAuth } from '@/lib/auth'
import { roleLabel } from '@/lib/labels'
import { cn } from '@/lib/utils'

const nav = [
  { to: '/', label: 'Дашборд', icon: LayoutDashboardIcon, end: true },
  { to: '/events', label: 'События', icon: MapIcon },
  { to: '/reports', label: 'Жалобы', icon: FlagIcon },
  { to: '/users', label: 'Пользователи', icon: UsersIcon },
  { to: '/tools', label: 'Инструменты', icon: WrenchIcon },
  { to: '/audit', label: 'Журнал действий', icon: ScrollTextIcon },
]

function NavItems({ onNavigate }: { onNavigate?: () => void }) {
  return (
    <nav className="flex flex-1 flex-col gap-1 p-3">
      {nav.map((item) => (
        <NavLink
          key={item.to}
          to={item.to}
          end={item.end}
          onClick={onNavigate}
          className={({ isActive }) =>
            cn(
              'flex items-center gap-2 rounded-md px-3 py-2 text-sm transition-colors',
              isActive
                ? 'bg-primary text-primary-foreground'
                : 'text-muted-foreground hover:bg-accent hover:text-accent-foreground',
            )
          }
        >
          <item.icon className="size-4" />
          {item.label}
        </NavLink>
      ))}
    </nav>
  )
}

function BrandBlock() {
  const { user } = useAuth()
  return (
    <div className="px-4 py-5">
      <p className="text-sm font-semibold tracking-tight">Выходи · Админка</p>
      <p className="mt-1 text-xs text-muted-foreground">
        {user?.email ?? user?.phone}
      </p>
      <p className="text-xs text-muted-foreground">
        {user ? roleLabel(user.role) : null}
      </p>
    </div>
  )
}

function LogoutButton({ className }: { className?: string }) {
  const { logout } = useAuth()
  return (
    <Button
      variant="outline"
      className={cn('w-full justify-start', className)}
      onClick={() => void logout()}
    >
      <LogOutIcon />
      Выйти
    </Button>
  )
}

export function AdminShell() {
  const [mobileOpen, setMobileOpen] = useState(false)

  return (
    <div className="flex min-h-svh">
      <aside className="hidden w-60 flex-col border-r bg-card md:flex">
        <BrandBlock />
        <Separator />
        <NavItems />
        <div className="p-3">
          <LogoutButton />
        </div>
      </aside>

      <Sheet open={mobileOpen} onOpenChange={setMobileOpen}>
        <SheetContent side="left" className="p-0">
          <SheetHeader className="sr-only">
            <SheetTitle>Меню</SheetTitle>
            <SheetDescription>Навигация админки</SheetDescription>
          </SheetHeader>
          <BrandBlock />
          <Separator />
          <NavItems onNavigate={() => setMobileOpen(false)} />
          <div className="mt-auto p-3">
            <LogoutButton />
          </div>
        </SheetContent>
      </Sheet>

      <div className="flex min-w-0 flex-1 flex-col">
        <header className="sticky top-0 z-40 flex h-14 items-center gap-3 border-b bg-background/95 px-4 backdrop-blur md:hidden">
          <Button
            type="button"
            variant="outline"
            size="icon"
            aria-label="Открыть меню"
            onClick={() => setMobileOpen(true)}
          >
            <MenuIcon />
          </Button>
          <p className="text-sm font-semibold">Админка</p>
        </header>
        <main className="flex-1 overflow-auto">
          <SessionExpiryWatcher />
          <div className="mx-auto max-w-6xl p-4 md:p-8">
            <Outlet />
          </div>
        </main>
      </div>
    </div>
  )
}
