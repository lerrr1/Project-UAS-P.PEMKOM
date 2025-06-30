from flask import Flask, render_template, request, redirect, jsonify
import mysql.connector
from config import db_config

app = Flask(__name__)
 
def get_db_connection():
    return mysql.connector.connect(**db_config)

@app.template_filter('rupiah')
def rupiah_format(value):
    try:
        value = float(value)
        return f"Rp {value:,.0f}".replace(",", ".")
    except (ValueError, TypeError):
        return "Rp 0"


@app.route('/')
def index():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM penjualan ORDER BY tanggal DESC")
    penjualan = cursor.fetchall()
    conn.close()
    return render_template('index.html', penjualan=penjualan)

@app.route('/tambah', methods=['POST'])
def tambah():
    print(request.form)
    tanggal = request.form.get('tanggal')
    produk = request.form.get('produk')
    jumlah = request.form.get('jumlah')
    harga = request.form.get('harga')
    
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("INSERT INTO penjualan (tanggal, produk, jumlah, harga) VALUES (%s, %s, %s, %s)",
                   (tanggal, produk, jumlah, harga))
    conn.commit()
    conn.close()
    return redirect('/')

@app.route('/edit/<int:id>')
def edit(id):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM penjualan WHERE id = %s", (id,))
    data = cursor.fetchone()
    conn.close()
    return render_template('edit.html', data=data)

@app.route('/update/<int:id>', methods=['POST'])
def update(id):
    tanggal = request.form['tanggal']
    produk = request.form['produk']
    jumlah = request.form['jumlah']
    harga = request.form['harga']

    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        UPDATE penjualan
        SET tanggal = %s, produk = %s, jumlah = %s, harga = %s
        WHERE id = %s
    """, (tanggal, produk, jumlah, harga, id))
    conn.commit()
    conn.close()
    return redirect('/')

@app.route('/delete/<int:id>')
def delete(id):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM penjualan WHERE id = %s", (id,))
    conn.commit()
    conn.close()
    return redirect('/')

@app.route('/api/penjualan', methods=['GET'])
def api_get_penjualan():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM penjualan ORDER BY tanggal DESC")
    data = cursor.fetchall()
    conn.close()
    return jsonify(data)

@app.route('/api/penjualan/<int:id>', methods=['GET'])
def api_get_penjualan_by_id(id):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM penjualan WHERE id = %s", (id,))
    data = cursor.fetchone()
    conn.close()
    if data:
        return jsonify(data)
    else:
        return jsonify({'message': 'Data tidak ditemukan'}), 404

@app.route('/api/penjualan', methods=['POST'])
def api_add_penjualan():
    data = request.get_json()
    tanggal = data.get('tanggal')
    produk = data.get('produk')
    jumlah = data.get('jumlah')
    harga = data.get('harga')

    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("INSERT INTO penjualan (tanggal, produk, jumlah, harga) VALUES (%s, %s, %s, %s)",
                   (tanggal, produk, jumlah, harga))
    conn.commit()
    conn.close()
    return jsonify({'message': 'Data berhasil ditambahkan'}), 201

@app.route('/api/penjualan/<int:id>', methods=['PUT'])
def api_update_penjualan(id):
    data = request.get_json()
    tanggal = data.get('tanggal')
    produk = data.get('produk')
    jumlah = data.get('jumlah')
    harga = data.get('harga')

    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        UPDATE penjualan
        SET tanggal = %s, produk = %s, jumlah = %s, harga = %s
        WHERE id = %s
    """, (tanggal, produk, jumlah, harga, id))
    conn.commit()
    conn.close()
    return jsonify({'message': 'Data berhasil diperbarui'})

@app.route('/api/penjualan/<int:id>', methods=['DELETE'])
def api_delete_penjualan(id):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM penjualan WHERE id = %s", (id,))
    conn.commit()
    conn.close()
    return jsonify({'message': 'Data berhasil dihapus'})

if __name__ == '__main__':
    app.run(debug=True)
