
import UIKit
import Firebase
import FirebaseDatabase

class DetallePublicacionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var usuarioLabel: UILabel!
    @IBOutlet weak var tituloLabel: UILabel!
    @IBOutlet weak var textoLabel: UILabel!
    @IBOutlet weak var comentarioTextField: UITextField!
    
    @IBOutlet weak var tableView: UITableView!
    
    var publicacion: Publicacion!
    var comentarios = [Comentario]()
    var databaseRef: DatabaseReference!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        databaseRef = Database.database().reference()
        setupUI()
        fetchComentarios()
    }

    func setupUI() {
        guard let publicacion = publicacion else {
            print("Error: Publicacion no encontrada")
            return
        }
        usuarioLabel.text = publicacion.usuario
        tituloLabel.text = publicacion.titulo
        textoLabel.text = publicacion.texto
    }

    func fetchComentarios() {
        guard let publicacion = publicacion else {
            print("Error: Publicacion no encontrada")
            return
        }
        databaseRef.child("comentarios").child(publicacion.id).observe(.value, with: { snapshot in
            var nuevosComentarios = [Comentario]()
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let dic = snapshot.value as? [String: Any],
                   let usuario = dic["usuario"] as? String,
                   let texto = dic["texto"] as? String {
                    let comentario = Comentario(id: snapshot.key, usuario: usuario, texto: texto)
                    nuevosComentarios.append(comentario)
                }
            }
            self.comentarios = nuevosComentarios
            self.tableView.reloadData()
        })
    }

    @IBAction func agregarComentarioTapped(_ sender: Any) {
        guard let user = Auth.auth().currentUser else { return }
        let usuario = user.email ?? "Usuario desconocido"
        let texto = comentarioTextField.text ?? ""

        let comentarioRef = databaseRef.child("comentarios").child(publicacion.id).childByAutoId()
        let comentarioData: [String: Any] = ["usuario": usuario, "texto": texto]

        comentarioRef.setValue(comentarioData) { (error, ref) in
            if let error = error {
                print("Error al guardar el comentario: \(error)")
                return
            }
            self.comentarioTextField.text = ""
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comentarios.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "comentarioCell", for: indexPath)
        let comentario = comentarios[indexPath.row]
        cell.textLabel?.text = comentario.texto
        cell.detailTextLabel?.text = comentario.usuario
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let comentario = comentarios[indexPath.row]
            let confirmacion = UIAlertController(title: "Eliminar Comentario", message: "¿Estás seguro de que quieres eliminar este comentario?", preferredStyle: .alert)
            confirmacion.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: nil))
            confirmacion.addAction(UIAlertAction(title: "Eliminar", style: .destructive, handler: { _ in
                self.eliminarComentario(comentario)
            }))
            present(confirmacion, animated: true, completion: nil)
        }
    }

    func eliminarComentario(_ comentario: Comentario) {
        guard let publicacion = publicacion else {
            print("Error: Publicacion no encontrada")
            return
        }
        let comentarioRef = databaseRef.child("comentarios").child(publicacion.id).child(comentario.id)
        comentarioRef.removeValue { error, _ in
            if let error = error {
                print("Error al eliminar comentario: \(error)")
            } else {
                print("Comentario eliminado correctamente")
                self.fetchComentarios()
            }
        }
    }
}
