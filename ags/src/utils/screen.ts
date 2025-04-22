import { DEFAULT } from "./consts"

const hyprland = await Service.import('hyprland')

/**
 * Returns a percentage of the screen height (similar to vh in css)
 * @param {number} percentage
 * @returns {number}
 * @example HPercentage(50)
 * @returns 960
 */
export const HPercentage = (percentage: number): number => {
    const totalHeight = hyprland.getMonitor(0)?.height
    return percentage / 100 * (totalHeight || DEFAULT.height)
}

/**
 * Returns a percentage of the screen width (similar to wh in css)
 * @param {number} percentage
 * @returns {number}
 * @example WPercentage(50)
 * @returns 540
 */
export const WPercentage = (percentage: number): number => {
    const totalWidth = hyprland.getMonitor(0)?.width
    return percentage / 100 * (totalWidth || DEFAULT.width)
}