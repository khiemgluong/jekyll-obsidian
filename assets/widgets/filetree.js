// function printFilesAndFolders(user, repo, path = '') {
//     const url = `https://api.github.com/repos/${user}/${repo}/contents/${path}`;
//     const xhr = new XMLHttpRequest();
//     xhr.open('GET', url);
//     xhr.onload = function() {
//         const response = JSON.parse(xhr.responseText);

//         response.forEach(item => {
//             if (item.type === 'dir') {
//                 console.log(`Directory: ${item.path}`);
//                 printFilesAndFolders(user, repo, item.path);
//             } else {
//                 console.log(`File: ${item.path}`);
//             }
//         });
//     };
//     xhr.send();
// }

// const user = 'khiemgluong'; // replace with your GitHub username
// const repo = 'khiemgluong.github.io'; // replace with your repository name
// printFilesAndFolders(user, repo);

// contents/blade-ballad

