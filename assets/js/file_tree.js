document.addEventListener("DOMContentLoaded", function() {
    function renderFileTree(container, nodes) {
      nodes.forEach(node => {
        const element = document.createElement('div');
        element.classList.add('file-tree-node');
        element.textContent = node.name;
  
        if (node.type === 'directory') {
          element.classList.add('directory');
          const childrenContainer = document.createElement('div');
          childrenContainer.classList.add('children');
          renderFileTree(childrenContainer, node.children);
          element.appendChild(childrenContainer);
        } else {
          element.classList.add('file');
        }
  
        container.appendChild(element);
      });
    }
  
    const fileTreeContainer = document.getElementById('file-tree');
    renderFileTree(fileTreeContainer, fileTreeData);
  });
  