export const OUTPUT_PATHS = [
  '.cursor/rules/agentic.mdc',
  '.agentic/reviewer-context.md',
  '.agentic/handoff/executor-to-reviewer.md',
  '.agentic/handoff/reviewer-to-executor.md',
];

export const MARKER = 'agentic-protocol: generated';

export function provenance({ protocolVersion, sourceSha }) {
  return [
    '<!--',
    MARKER,
    `protocol_version: ${protocolVersion}`,
    `source_sha: ${sourceSha}`,
    'generator: scripts/generate-adapters.mjs',
    '-->',
  ].join('\n');
}

function document(parts) {
  const body = parts
    .map((part) => String(part).replace(/\r\n/g, '\n').trim())
    .filter((part) => part.length > 0)
    .join('\n\n');
  return `${body}\n`;
}

export function renderAdapters({ protocolVersion, sourceSha, protocolMarkdown, templates }) {
  const header = provenance({ protocolVersion, sourceSha });
  const cursor = document([
    ['---', 'description: Agentic protocol rules (generated)', 'alwaysApply: true', '---'].join('\n'),
    header,
    'Сгенерировано из protocol/. Не редактировать вручную. Повторная генерация: node scripts/generate-adapters.mjs --write.',
    protocolMarkdown,
  ]);
  const reviewer = document([
    header,
    [
      '# Контекст для ревьюера',
      '',
      'Этот файл — переносимый пакет контекста.',
      'Его передаёт человек в сессию Perplexity вместе с отчётом исполнителя.',
      'Perplexity не читает этот файл из репозитория автоматически и не запускается из него.',
      'Исполнитель не заполняет вердикт ревьюера.',
    ].join('\n'),
    protocolMarkdown,
  ]);
  const executorToReviewer = document([
    header,
    [
      '# Передача: исполнитель → ревьюер',
      '',
      'Заполните отчёт. Шаблон формы ниже. Нормативные правила — в тексте протокола выше.',
      'Не добавляйте решение ревьюера.',
    ].join('\n'),
    protocolMarkdown,
    templates['report.md'],
  ]);
  const reviewerToExecutor = document([
    header,
    [
      '# Передача: ревьюер → исполнитель',
      '',
      'Заполните вердикт. Шаблон формы ниже. Нормативные правила — в тексте протокола выше.',
    ].join('\n'),
    protocolMarkdown,
    templates['verdict.md'],
  ]);

  return new Map([
    [OUTPUT_PATHS[0], cursor],
    [OUTPUT_PATHS[1], reviewer],
    [OUTPUT_PATHS[2], executorToReviewer],
    [OUTPUT_PATHS[3], reviewerToExecutor],
  ]);
}
