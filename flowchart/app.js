const nodes = Array.from(document.querySelectorAll('.node'));
const chart = document.getElementById('chart');
const svg = document.getElementById('lines');
const stepCount = document.getElementById('step-count');
const stepTotal = document.getElementById('step-total');
const nextButton = document.getElementById('next');
const prevButton = document.getElementById('prev');
const resetButton = document.getElementById('reset');

const edges = [
  { id: 'e1-2', from: 'step-1', to: 'step-2', fromAnchor: 'right', toAnchor: 'left' },
  { id: 'e2-3', from: 'step-2', to: 'step-3', fromAnchor: 'right', toAnchor: 'left' },
  { id: 'e3-4', from: 'step-3', to: 'step-4', fromAnchor: 'bottom', toAnchor: 'top' },
  { id: 'e4-5', from: 'step-4', to: 'step-5', fromAnchor: 'bottom', toAnchor: 'top' },
  { id: 'e4-12', from: 'step-4', to: 'step-12', fromAnchor: 'right', toAnchor: 'left' },
  { id: 'e5-6', from: 'step-5', to: 'step-6', fromAnchor: 'left', toAnchor: 'right' },
  { id: 'e6-7', from: 'step-6', to: 'step-7', fromAnchor: 'left', toAnchor: 'right' },
  { id: 'e7-8', from: 'step-7', to: 'step-8', fromAnchor: 'bottom', toAnchor: 'top' },
  { id: 'e8-9', from: 'step-8', to: 'step-9', fromAnchor: 'right', toAnchor: 'left' },
  { id: 'e9-10', from: 'step-9', to: 'step-10', fromAnchor: 'right', toAnchor: 'left' },
  { id: 'e10-5', from: 'step-10', to: 'step-5', fromAnchor: 'top', toAnchor: 'bottom' },
  { id: 'e10-11', from: 'step-10', to: 'step-11', fromAnchor: 'bottom', toAnchor: 'top' },
];

const labels = [
  { id: 'label-yes-quality', edge: 'e4-5', offsetX: 16, offsetY: -18 },
  { id: 'label-no-quality', edge: 'e4-12', offsetX: 16, offsetY: -18 },
  { id: 'label-yes', edge: 'e10-5', offsetX: -18, offsetY: -20 },
  { id: 'label-no', edge: 'e10-11', offsetX: 18, offsetY: 10 },
];

const edgeElements = new Map();
let currentStep = 1;
const totalSteps = nodes.reduce(
  (maxStep, node) => Math.max(maxStep, Number(node.dataset.step || 0)),
  0,
);

function getStepIndex(nodeId) {
  const el = document.getElementById(nodeId);
  if (!el) return 0;
  return Number(el.dataset.step || 0);
}

function anchorPoint(element, anchor) {
  const chartRect = chart.getBoundingClientRect();
  const rect = element.getBoundingClientRect();
  const x = rect.left - chartRect.left;
  const y = rect.top - chartRect.top;

  switch (anchor) {
    case 'top':
      return { x: x + rect.width / 2, y: y };
    case 'bottom':
      return { x: x + rect.width / 2, y: y + rect.height };
    case 'left':
      return { x: x, y: y + rect.height / 2 };
    case 'right':
      return { x: x + rect.width, y: y + rect.height / 2 };
    default:
      return { x: x + rect.width / 2, y: y + rect.height / 2 };
  }
}

function createEdgePath(start, end) {
  const midX = (start.x + end.x) / 2;
  return `M ${start.x} ${start.y} L ${midX} ${start.y} L ${midX} ${end.y} L ${end.x} ${end.y}`;
}

function ensureEdges() {
  edges.forEach((edge) => {
    if (edgeElements.has(edge.id)) return;
    const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    path.setAttribute('id', edge.id);
    path.setAttribute('fill', 'none');
    path.setAttribute('stroke', 'var(--ink)');
    path.setAttribute('stroke-width', '2');
    path.setAttribute('marker-end', 'url(#arrow)');
    path.style.opacity = '0';
    path.style.transition = 'opacity 0.4s ease';
    svg.appendChild(path);
    edgeElements.set(edge.id, path);
  });
}

function layoutEdges() {
  const rect = chart.getBoundingClientRect();
  svg.setAttribute('viewBox', `0 0 ${rect.width} ${rect.height}`);
  svg.setAttribute('width', rect.width);
  svg.setAttribute('height', rect.height);

  edges.forEach((edge) => {
    const fromEl = document.getElementById(edge.from);
    const toEl = document.getElementById(edge.to);
    if (!fromEl || !toEl) return;
    const start = anchorPoint(fromEl, edge.fromAnchor);
    const end = anchorPoint(toEl, edge.toAnchor);
    const path = edgeElements.get(edge.id);
    if (path) {
      path.setAttribute('d', createEdgePath(start, end));
    }
  });

  labels.forEach((label) => {
    const labelEl = document.getElementById(label.id);
    const edgeDef = edges.find((edge) => edge.id === label.edge);
    if (!labelEl || !edgeDef) return;
    const fromEl = document.getElementById(edgeDef.from);
    const toEl = document.getElementById(edgeDef.to);
    if (!fromEl || !toEl) return;
    const start = anchorPoint(fromEl, edgeDef.fromAnchor);
    const end = anchorPoint(toEl, edgeDef.toAnchor);
    const midX = (start.x + end.x) / 2 + label.offsetX;
    const midY = (start.y + end.y) / 2 + label.offsetY;
    labelEl.style.left = `${midX}px`;
    labelEl.style.top = `${midY}px`;
  });
}

function updateVisibility() {
  nodes.forEach((node) => {
    const step = Number(node.dataset.step || 0);
    node.classList.toggle('is-visible', step <= currentStep);
  });

  edges.forEach((edge) => {
    const edgeStep = Math.max(getStepIndex(edge.from), getStepIndex(edge.to));
    const path = edgeElements.get(edge.id);
    if (path) {
      path.style.opacity = currentStep >= edgeStep ? '1' : '0';
    }
  });

  labels.forEach((label) => {
    const labelEl = document.getElementById(label.id);
    const edgeDef = edges.find((edge) => edge.id === label.edge);
    if (!labelEl || !edgeDef) return;
    const edgeStep = Math.max(getStepIndex(edgeDef.from), getStepIndex(edgeDef.to));
    labelEl.classList.toggle('is-visible', currentStep >= edgeStep);
  });

  stepCount.textContent = `${currentStep}`;
  prevButton.disabled = currentStep <= 1;
  nextButton.disabled = currentStep >= totalSteps;
}

function setStep(step) {
  currentStep = Math.min(Math.max(step, 1), totalSteps);
  updateVisibility();
}

ensureEdges();
layoutEdges();
updateVisibility();

if (stepTotal) {
  stepTotal.textContent = `${totalSteps}`;
}

nextButton.addEventListener('click', () => setStep(currentStep + 1));
prevButton.addEventListener('click', () => setStep(currentStep - 1));
resetButton.addEventListener('click', () => setStep(1));

window.addEventListener('resize', () => {
  layoutEdges();
});
