export function truncateText(
  inputString: string,
  frontLetters: number,
  backLetters: number,
): string {
  if (inputString.length < frontLetters + backLetters) {
    return inputString;
  }

  const firstNine = inputString.substring(0, frontLetters);
  const lastFive = inputString.slice(-backLetters);

  return `${firstNine}.....${lastFive}`;
}
