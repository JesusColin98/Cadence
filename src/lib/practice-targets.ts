// FILE: src/lib/practice-targets.ts
import practiceTargetsData from "@/backend/data/practice_targets.json";

interface PracticeTargetSegment {
  text: string;
  start: number;
  end: number;
}

interface PracticeTargetRecord {
  ipa: string;
  category: string;
  focus_phoneme: string;
  cue: string | null;
  segments: PracticeTargetSegment[];
}

export interface PracticeTargetOption {
  word: string;
  label: string;
  ipa: string;
  category: string;
  cue: string;
}

const practiceTargets = practiceTargetsData.words as Record<string, PracticeTargetRecord>;

function toLabel(word: string) {
  return word.slice(0, 1).toUpperCase() + word.slice(1);
}

function buildCue(word: string, target: PracticeTargetRecord) {
  if (target.cue) {
    return target.cue;
  }

  const focus = target.segments
    .slice(0, 2)
    .map((segment) => segment.text)
    .join(" and ");

  return `Keep ${focus || "the sound"} clean, then compare the full target against /${target.ipa}/.`;
}

export const PRACTICE_TARGET_OPTIONS: PracticeTargetOption[] = Object.entries(
  practiceTargets,
)
  .map(([word, target]) => ({
    word,
    label: toLabel(word),
    ipa: `/${target.ipa}/`,
    category: target.category,
    cue: buildCue(word, target),
  }))
  .sort((left, right) => left.label.localeCompare(right.label));

export function getPracticeTarget(word: string) {
  return (
    PRACTICE_TARGET_OPTIONS.find(
      (target) => target.word === word.trim().toLowerCase(),
    ) ?? PRACTICE_TARGET_OPTIONS[0]
  );
}
