import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { cn } from '@/lib/utils'

function formatMetadata(metadata: unknown): string {
  try {
    return JSON.stringify(metadata, null, 2)
  } catch {
    return String(metadata)
  }
}

/** Compact preview + expand for audit log JSON metadata. */
export function AuditMetadataCell({ metadata }: { metadata: unknown }) {
  const [open, setOpen] = useState(false)

  if (metadata == null) {
    return <span className="text-muted-foreground">—</span>
  }

  const pretty = formatMetadata(metadata)
  const compact =
    typeof metadata === 'object'
      ? Object.entries(metadata as Record<string, unknown>)
          .slice(0, 3)
          .map(([key, value]) => {
            const v =
              value === null || typeof value === 'string' || typeof value === 'number'
                ? String(value)
                : JSON.stringify(value)
            return `${key}: ${v}`
          })
          .join(' · ')
      : pretty

  return (
    <div className="max-w-[280px] space-y-1">
      <p
        className={cn(
          'font-mono text-xs text-muted-foreground',
          open ? 'whitespace-pre-wrap break-all' : 'truncate',
        )}
        title={compact}
      >
        {open ? pretty : compact || '—'}
      </p>
      {pretty.length > 40 ? (
        <Button
          type="button"
          size="sm"
          variant="ghost"
          className="h-6 px-1 text-xs"
          onClick={() => setOpen((v) => !v)}
        >
          {open ? 'Свернуть' : 'Развернуть'}
        </Button>
      ) : null}
    </div>
  )
}
