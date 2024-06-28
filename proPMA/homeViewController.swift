import UIKit
import Firebase
import FirebaseDatabase

class homeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var publicaciones = [Publicacion]()
    var databaseRef: DatabaseReference!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        databaseRef = Database.database().reference()
        fetchPublicaciones()
    }

    func fetchPublicaciones() {
        databaseRef.child("publicaciones").observe(.value, with: { snapshot in
            var nuevasPublicaciones = [Publicacion]()
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let dic = snapshot.value as? [String: Any],
                   let usuario = dic["usuario"] as? String,
                   let titulo = dic["titulo"] as? String,
                   let texto = dic["texto"] as? String {
                    let publicacion = Publicacion(id: snapshot.key, usuario: usuario, titulo: titulo, texto: texto)
                    nuevasPublicaciones.append(publicacion)
                }
            }
            self.publicaciones = nuevasPublicaciones
            self.tableView.reloadData()
        })
    }
    
    @IBAction func cerrarSesionTapped(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            dismiss(animated: true, completion: nil)
        } catch {
            print("Error al cerrar sesión: \(error.localizedDescription)")
        }
    }

    @IBAction func agregarPublicacionTapped(_ sender: Any) {
        performSegue(withIdentifier: "agregarPublicacionSegue", sender: nil)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return publicaciones.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "publicacionCell", for: indexPath)
        let publicacion = publicaciones[indexPath.row]
        cell.textLabel?.text = publicacion.titulo
        cell.detailTextLabel?.text = publicacion.usuario
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let publicacion = publicaciones[indexPath.row]
        performSegue(withIdentifier: "mostrarDetallePublicacionSegue", sender: publicacion)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let publicacion = publicaciones[indexPath.row]
            eliminarPublicacion(publicacion)
        }
    }
    
    func eliminarPublicacion(_ publicacion: Publicacion) {
        let publicacionRef = databaseRef.child("publicaciones").child(publicacion.id)
        publicacionRef.removeValue { error, _ in
            if let error = error {
                print("Error al eliminar publicación: \(error)")
            } else {
                // Eliminar comentarios relacionados
                let comentariosRef = self.databaseRef.child("comentarios").child(publicacion.id)
                comentariosRef.removeValue { error, _ in
                    if let error = error {
                        print("Error al eliminar comentarios: \(error)")
                    } else {
                        print("Publicación y comentarios eliminados correctamente")
                        self.fetchPublicaciones()
                    }
                }
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "mostrarDetallePublicacionSegue" {
            if let destinoVC = segue.destination as? DetallePublicacionViewController, let publicacion = sender as? Publicacion {
                destinoVC.publicacion = publicacion
            }
        }
    }
    
}
