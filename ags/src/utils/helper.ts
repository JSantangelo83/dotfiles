
/**
 * Get time label from seconds
 * @param seconds
 * @returns string
 * @example getTimeLabel(3661)
 * @returns '1h 1m'
 */
export function getTimeLabel(seconds: number): string {
    if (seconds < 0) {
        return ''
    }
    let hours = Math.floor(seconds / 3600)
    let minutes = Math.floor((seconds % 3600) / 60)
    let time = ''
    if (hours > 0) {
        time += `${hours}h `
    }
    if (minutes > 0) {
        time += `${minutes}m `
    }
    return time
}