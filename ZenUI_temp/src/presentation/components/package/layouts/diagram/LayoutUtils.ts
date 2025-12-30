import { DiagramEdgeOptions, LayoutNode } from "./Diagram.types";

// ==================== CONSTANTS ====================
export const FILE_GROUP_PADDING = 40; // Increased padding for better spacing
export const FILE_GROUP_MARGIN = 180; // TĂNG: Margin giữa các wrapper xa hơn
export const CODE_NODE_WIDTH = 420; // Slightly smaller for better horizontal fit
export const CODE_NODE_MIN_HEIGHT = 206;
export const CODE_NODE_DEFAULT_HEIGHT = 300; // Reduced default height
export const DECLARATION_NODE_WIDTH = 330; // Reduced width
export const DECLARATION_NODE_HEIGHT = 180; // Reduced height
export const MIN_NODE_SPACING = 50; // Further increased for better visual separation
export const DECLARATION_GRID_COLUMNS = 3; // Increased from 2 to 3
export const DECLARATION_GRID_SPACING = 60; // Further increased for better spacing
export const MIN_CONTAINER_SPACING = 200; // TĂNG: Khoảng cách tối thiểu giữa các container

// ==================== HELPER: GROUP NODES BY CLUSTER ====================
export interface ClusterGroup {
  id: string; // wrapper ID or file name
  type: "wrapper" | "file";
  label: string;
  nodes: LayoutNode[];
  edges: DiagramEdgeOptions[];
}

export function groupNodesByCluster(
  nodes: LayoutNode[],
  edges: DiagramEdgeOptions[]
): ClusterGroup[] {
  const groups = new Map<string, ClusterGroup>();

  nodes.forEach((node) => {
    // Determine Cluster ID
    // 1. If node has groupId (from Wrapper), use that.
    // 2. Else use fileName.
    // 3. Else use "unknown".
    let clusterId = node.groupId;
    let type: "wrapper" | "file" = "wrapper";

    if (!clusterId) {
      clusterId = node.file || "unknown";
      type = "file";
    }

    if (!groups.has(clusterId)) {
      groups.set(clusterId, {
        id: clusterId,
        type,
        label: clusterId,
        nodes: [],
        edges: [],
      });
    }
    groups.get(clusterId)!.nodes.push(node);
  });

  // Populate internal edges
  const clusters = Array.from(groups.values());
  clusters.forEach((group) => {
    const nodeIds = new Set(group.nodes.map((n) => n.id));
    group.edges = edges.filter(
      (edge) => nodeIds.has(edge.from) && nodeIds.has(edge.to)
    );
  });

  return clusters;
}

export interface FileGroup {
  fileName: string;
  nodes: LayoutNode[];
  edges: DiagramEdgeOptions[];
}

export function groupNodesByFile(
  nodes: LayoutNode[],
  edges: DiagramEdgeOptions[]
): FileGroup[] {
  // Legacy support or fallback
  const nodesByFile = new Map<string, LayoutNode[]>();
  // ... existing implementation ...
  nodes.forEach((node) => {
    const file = node.file || "unknown";
    if (!nodesByFile.has(file)) {
      nodesByFile.set(file, []);
    }
    nodesByFile.get(file)!.push(node);
  });

  const fileGroups: FileGroup[] = [];
  nodesByFile.forEach((groupNodes, fileName) => {
    const nodeIds = new Set(groupNodes.map((n) => n.id));
    const internalEdges = edges.filter(
      (edge) => nodeIds.has(edge.from) && nodeIds.has(edge.to)
    );

    fileGroups.push({
      fileName,
      nodes: groupNodes,
      edges: internalEdges,
    });
  });

  return fileGroups;
}

// ==================== HELPER: CALCULATE CROSS-FILE EDGES ====================
export function getCrossFileEdges(
  groups: FileGroup[],
  allEdges: DiagramEdgeOptions[]
): DiagramEdgeOptions[] {
  const crossFileEdges = allEdges.filter((edge) => {
    const sourceGroup = groups.find((g) =>
      g.nodes.some((n) => n.id === edge.from)
    );
    const targetGroup = groups.find((g) =>
      g.nodes.some((n) => n.id === edge.to)
    );

    return (
      sourceGroup &&
      targetGroup &&
      sourceGroup.fileName !== targetGroup.fileName
    );
  });

  return crossFileEdges;
}

// ==================== HELPER: CHECK RECTANGLE OVERLAP ====================
export function rectanglesOverlap(
  rect1: { x: number; y: number; width: number; height: number },
  rect2: { x: number; y: number; width: number; height: number }
): boolean {
  return (
    rect1.x < rect2.x + rect2.width + MIN_NODE_SPACING &&
    rect1.x + rect1.width + MIN_NODE_SPACING > rect2.x &&
    rect1.y < rect2.y + rect2.height + MIN_NODE_SPACING &&
    rect1.y + rect1.height + MIN_NODE_SPACING > rect2.y
  );
}
