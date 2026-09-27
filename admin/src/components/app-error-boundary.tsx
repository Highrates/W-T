import { Component, type ErrorInfo, type ReactNode } from 'react'
import { Button } from '@/components/ui/button'

type Props = {
  children: ReactNode
}

type State = {
  error: Error | null
}

export class AppErrorBoundary extends Component<Props, State> {
  state: State = { error: null }

  static getDerivedStateFromError(error: Error): State {
    return { error }
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    console.error('Admin SPA crash', error, info.componentStack)
  }

  private reload = () => {
    this.setState({ error: null })
    window.location.assign('/')
  }

  render() {
    if (!this.state.error) {
      return this.props.children
    }

    return (
      <div className="flex min-h-svh flex-col items-center justify-center gap-4 p-6 text-center">
        <h1 className="text-2xl font-semibold">Что-то сломалось</h1>
        <p className="max-w-md text-sm text-muted-foreground">
          Необработанная ошибка интерфейса. Можно перезагрузить админку — данные
          на сервере не затронуты.
        </p>
        <pre className="max-w-lg overflow-auto rounded-md border bg-muted/40 p-3 text-left font-mono text-xs text-muted-foreground">
          {this.state.error.message}
        </pre>
        <Button type="button" onClick={this.reload}>
          На дашборд
        </Button>
      </div>
    )
  }
}
